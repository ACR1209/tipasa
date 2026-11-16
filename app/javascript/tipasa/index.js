import { Controller } from "@hotwired/stimulus";
import { driver } from "driver.js";

// The controller whose tour is on screen, so a replay elsewhere can close it first.
let active = null;

// Register as "tipasa": application.register("tipasa", TipasaController)
// The tipasa_button and tipasa_autostart helpers render the element and its values.
export default class TipasaController extends Controller {
  static values = {
    slug: String,
    url: String,
    completeUrl: String,
    labels: Object,
    replay: Boolean,
    resume: Boolean,
    manual: Boolean
  };

  // A manual tour (a help button) waits for a click on replay instead of starting on load.
  connect() {
    if (!this.manualValue) this.load();
  }

  // Starts the tour again even if it was completed, closing whichever tour is open.
  // Clicks while the tour loads are ignored, so a double click doesn't start it twice.
  async replay() {
    if (this.loading) return;
    this.loading = true;
    try {
      active?.stop();
      this.replayValue = true;
      await this.load();
    } finally {
      this.loading = false;
    }
  }

  // Leaving the page isn't finishing the tour, so nothing is recorded.
  disconnect() {
    this.end({ record: false });
  }

  async load() {
    const response = await fetch(this.urlValue, { credentials: "same-origin", headers: { Accept: "application/json" } });
    if (!response.ok) return;

    const tour = await response.json();
    if (tour.completed && !this.replayValue) return;

    this.steps = tour.steps;
    // Fixed when the tour starts, so skipped steps don't make the counter jump around.
    this.progressIds = this.steps.filter((step) => this.present(step)).map((step) => step.id);

    // Remembers the step on screen, so a tour closed with the x (or left) can be reopened there
    // with ?resume=1. Any other start begins at the first step.
    const resumeAt = this.resumeValue ? this.steps.findIndex((step) => step.id === this.savedStep()) : -1;
    this.go(resumeAt >= 0 ? resumeAt : this.nextIndex(-1));
  }

  // Shows step `index`, building the driver if it isn't on screen (first step, or back from a pause).
  async go(index) {
    if (index < 0) return this.finish();

    const step = this.steps[index];
    if (step.wait_for) await this.waitFor(step.wait_for);
    if (!this.element.isConnected) return;

    if (this.driver?.isActive()) {
      this.driver.moveTo(index);
    } else {
      this.build();
      this.driver.drive(index);
    }
  }

  build() {
    active = this;
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    this.driver = driver({
      steps: this.steps.map((step, index) => this.driveStep(step, index)),
      animate: !reduceMotion,
      smoothScroll: !reduceMotion,
      overlayClickBehavior: "none",
      // The arrow keys would move the driver past our own next/back (ping_url, next_url, optional steps).
      allowKeyboardControl: false,
      popoverClass: "tipasa-popover"
    });
    this.onKeydown ||= (event) => event.key === "Escape" && this.stop();
    document.addEventListener("keydown", this.onKeydown);
  }

  // Takes the tour off screen without ending it (the user is acting in a modal); go() builds it again.
  pause() {
    document.removeEventListener("keydown", this.onKeydown);
    this.driver?.destroy();
  }

  driveStep(step, index) {
    const labels = this.labelsValue;
    const last = index === this.steps.length - 1;
    // A step that waits for the user (await_more, await_modal, advance_on) has no Next: doing the action moves the tour on.
    const buttons = ["close", ...(index > 0 ? ["previous"] : []), ...(this.waitsForUser(step) ? [] : ["next"])];
    const nextText = step.button || (last ? labels.done : labels.next);

    return {
      element: step.element_selector || undefined,
      allowedElements: step.extra_highlights,
      popover: {
        title: step.title,
        description: step.text,
        side: this.placement(step),
        align: "center",
        showButtons: buttons,
        nextBtnText: nextText,
        doneBtnText: nextText,
        prevBtnText: labels.back,
        closeBtnLabel: labels.close,
        onNextClick: () => this.advance(step),
        onPrevClick: () => this.go(this.previousIndex(index)),
        onCloseClick: () => this.stop(),
        onPopoverRender: (popover) => this.decorate(popover, step)
      },
      onHighlightStarted: (element) => {
        // Padding and radius are driver-wide settings, so each step sets its own before it's drawn.
        this.driver.setConfig({ ...this.driver.getConfig(), stagePadding: this.padding(step), stageRadius: step.radius ?? 8 });
        element?.classList.add(...this.highlightClasses(step));
        this.savedStep(step.id);
      },
      onHighlighted: () => {
        if (step.advance_on) this.advanceOnEvent(step);
        if (step.await_more || step.await_modal) this.awaitMore(step, index);
      },
      onDeselected: (element) => element?.classList.remove(...this.highlightClasses(step))
    };
  }

  advance(step) {
    if (step.ping_url) this.ping(step.ping_url);
    if (step.next_url) {
      this.finish();
      window.Turbo ? window.Turbo.visit(step.next_url) : window.location.assign(step.next_url);
    } else if (step.finish_url) {
      this.finish();
      this.post(step.finish_url);
    } else {
      this.go(this.nextIndex(this.steps.indexOf(step)));
    }
  }

  // The user went through the whole tour.
  finish() {
    this.savedStep(null);
    this.end({ record: true });
  }

  // The user closed the tour (x, Escape, or another tour's replay). It counts as completed,
  // but keeps the step for ?resume=1.
  stop() {
    this.end({ record: true });
  }

  end({ record }) {
    this.observer?.disconnect();
    this.advanceAbort?.abort();
    this.cancelWait?.();
    clearTimeout(this.reshowTimer);
    document.removeEventListener("keydown", this.onKeydown);
    this.driver?.destroy();
    this.driver = null;
    if (active === this) active = null;
    if (record && this.element.isConnected) this.complete();
  }

  // keepalive: the request survives a next_url visit right after.
  complete() {
    fetch(this.completeUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfToken(), "Content-Type": "application/json", Accept: "application/json" },
      credentials: "same-origin",
      body: "{}",
      keepalive: true
    });
  }

  // An optional step is skipped when its element isn't on the page (e.g. an empty list).
  present(step) {
    return !step.optional || Boolean(document.querySelector(step.element_selector));
  }

  nextIndex(from) {
    for (let i = from + 1; i < this.steps.length; i++) if (this.present(this.steps[i])) return i;
    return -1;
  }

  previousIndex(from) {
    for (let i = from - 1; i >= 0; i--) if (this.present(this.steps[i])) return i;
    return from;
  }

  // On a phone there is no room beside an element, so a left/right step gets pushed over it.
  // It goes below instead.
  placement(step) {
    const side = step.attach_to || "bottom";
    const sideways = side === "left" || side === "right";
    return sideways && window.matchMedia("(max-width: 767px)").matches ? "bottom" : side;
  }

  waitsForUser(step) {
    return Boolean(step.await_more || step.await_modal || step.advance_on);
  }

  // Steps that ask the user to act get a wider cut-out, so the pulse around the element isn't dimmed.
  padding(step) {
    return step.padding ?? (this.waitsForUser(step) ? 16 : 6);
  }

  highlightClasses(step) {
    const name = step.highlight_class || (this.waitsForUser(step) ? "tipasa-pulse" : null);
    return name ? name.split(" ") : [];
  }

  // Adds the step counter and, on a step with no Next, what it's waiting for (otherwise it looks stuck).
  decorate(popover, step) {
    popover.footer.querySelectorAll(".tipasa-progress, .tipasa-waiting").forEach((extra) => extra.remove());
    const position = this.progressIds.indexOf(step.id) + 1;
    const extras = [];
    if (position && this.progressIds.length > 1) {
      extras.push(this.span("tipasa-progress", this.labelsValue.progress.replace("%{current}", position).replace("%{total}", this.progressIds.length)));
    }
    if (this.waitsForUser(step)) {
      const hint = this.span("tipasa-waiting", this.labelsValue.waiting);
      hint.prepend(this.span("tipasa-waiting-dot", ""));
      extras.push(hint);
    }
    if (extras.length === 0) return;

    popover.progress.style.display = "none";
    popover.footer.style.display = "flex";
    popover.footer.prepend(...extras);
  }

  span(className, text) {
    const span = document.createElement("span");
    span.className = className;
    span.textContent = text;
    return span;
  }

  // Holds the step until its element renders (e.g. a Turbo frame still loading). After 3s it shows anyway.
  // Closing or leaving the tour cancels the wait, so the step never shows up on another page.
  waitFor(selector) {
    if (document.querySelector(selector)) return Promise.resolve();

    this.cancelWait?.();
    return new Promise((resolve) => {
      const cancel = () => { observer.disconnect(); clearTimeout(timer); };
      const done = () => { cancel(); resolve(); };
      const observer = new MutationObserver(() => document.querySelector(selector) && done());
      const timer = setTimeout(done, 3000);
      this.cancelWait = () => { cancel(); resolve(); };
      observer.observe(document.body, { childList: true, subtree: true });
    });
  }

  // Not driver.js's advanceOn, which moves to the next step and would skip ping_url, next_url and finish_url.
  advanceOnEvent(step) {
    this.advanceAbort?.abort();
    this.advanceAbort = new AbortController();
    document.querySelector(step.element_selector)?.addEventListener(step.advance_on, () => {
      this.advanceAbort.abort();
      if (this.driver?.getActiveStep() && this.steps[this.driver.getActiveIndex()] === step) this.advance(step);
    }, { signal: this.advanceAbort.signal });
  }

  // Hides the tour while the user does the step in a modal and moves on once more elements match
  // await_more (e.g. one more paid row). If the modal closes without that, the step comes back,
  // after a pause because the page can refresh a moment after the modal closes.
  // await_modal (no selector) only waits out the modal, which can run its own tour.
  awaitMore(step, index) {
    const selector = typeof step.await_more === "string" ? step.await_more : null;
    const count = () => (selector ? document.querySelectorAll(selector).length : 0);
    const before = count();
    document.querySelector(step.element_selector)?.addEventListener("click", () => this.pause(), { once: true });

    let modalOpened = false;
    this.observer?.disconnect();
    clearTimeout(this.reshowTimer);
    this.observer = new MutationObserver(() => {
      const modalOpen = Boolean(document.querySelector("dialog:modal"));
      modalOpened ||= modalOpen;
      if (modalOpen) return;

      if (count() > before) {
        clearTimeout(this.reshowTimer);
        this.observer.disconnect();
        this.go(this.nextIndex(index));
      } else if (modalOpened && !this.driver?.isActive()) {
        clearTimeout(this.reshowTimer);
        this.reshowTimer = setTimeout(() => {
          if (count() > before) return;
          this.observer.disconnect();
          this.go(index);
        }, 1500);
      }
    });
    this.observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["open"] });
  }

  // sessionStorage can be unavailable (private mode, blocked storage); the tour then starts over.
  savedStep(id) {
    const key = `tipasa-step:${this.slugValue}`;
    try {
      if (id === undefined) return sessionStorage.getItem(key);
      if (id) sessionStorage.setItem(key, id);
      else sessionStorage.removeItem(key);
    } catch {
      return null;
    }
  }

  csrfToken() {
    return document.querySelector("meta[name=csrf-token]")?.content;
  }

  // keepalive: the request survives a page change right after.
  ping(url) {
    fetch(url, { method: "POST", headers: { "X-CSRF-Token": this.csrfToken() }, credentials: "same-origin", keepalive: true });
  }

  post(url) {
    const form = document.createElement("form");
    form.method = "post";
    form.action = url;
    form.dataset.turbo = "false";
    const token = document.createElement("input");
    token.type = "hidden";
    token.name = "authenticity_token";
    token.value = this.csrfToken() || "";
    form.append(token);
    document.body.append(form);
    form.submit();
  }
}
