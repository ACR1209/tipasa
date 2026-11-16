# Tipasa

> In the midst of winter, I found there was, within me, an invincible summer. 
> - Albert Camus on  _Return to Tipasa_

Guided product tours for Rails, written in YAML.

Tipasa is a Rails engine plus a Stimulus controller. You describe each tour in `config/tours/<slug>.yml`; the engine serves it, records who completed it, and the controller walks the user through it with [driver.js](https://driverjs.com) (MIT).


## Installation

```ruby
# Gemfile
gem "tipasa"
```

```bash
bundle install
bin/rails g tipasa:install   # initializer, config/tours/, route, migration
bin/rails db:migrate
yarn add tipasa              # or npm install tipasa
```

Register the controller (esbuild, Vite, webpack...):

```js
// app/javascript/controllers/index.js
import TipasaController from "tipasa";
application.register("tipasa", TipasaController);
```

Load the styles in your CSS build (Tailwind CLI, cssbundling, PostCSS):

```css
@import "tipasa/tipasa.css";
```

Importmap apps aren't supported yet.

## Writing a tour

The file name is the slug: `config/tours/agenda.yml` is the `agenda` tour.

```yaml
name: "Agenda"
description: "The agenda in four steps"
active: true          # default true; false hides the tour
for: [User]           # optional: only these owner classes see it (see below)
steps:
  - id: "welcome"
    title: "Welcome!"
    text: "A step without element_selector is centered. <b>HTML</b> is allowed."
  - id: "calendar"
    title: "Calendar"
    text: "Move between dates here."
    element_selector: "#calendar"
```

Step keys:

| Key | What it does |
|---|---|
| `id`, `title`, `text` | Identity and content. `text` is rendered as HTML, so only put trusted content in it. |
| `element_selector` | What the step points at. Without it the step is centered. |
| `attach_to` | `top`, `right`, `bottom` (default) or `left`. Left/right fall back to bottom on phones. |
| `optional` | Skip the step when `element_selector` isn't on the page. |
| `wait_for` | Selector to wait for (up to 3s) before showing the step. |
| `padding`, `radius` | Pixels around the highlighted element, and its corner radius. |
| `highlight_class` | Class added to the element. Steps that wait for the user pulse (`tipasa-pulse`) by default. |
| `extra_highlights` | More selectors kept visible and clickable. |
| `advance_on` | Event on the element (e.g. `click`) that moves on. The step has no Next button. |
| `await_more` | Selector: the tour hides while the user works in a modal and moves on when more elements match it (e.g. one more row). |
| `await_modal` | `true`: the tour hides until the modal the element opens is closed. |
| `button` | Text for this step's Next button. |
| `ping_url` | POSTed (with the CSRF token) when the user presses Next. |
| `next_url` | Completes the tour and visits this URL (Turbo if present), e.g. `/people?tour=people`. |
| `finish_url` | Completes the tour and submits a POST form to this URL. |

## Showing a tour

```erb
<%# In the layout: starts the tour named in ?tour=, e.g. /agenda?tour=agenda %>
<%= tipasa_autostart %>

<%# A help button that replays the tour. Unstyled: bring your own classes and icon. %>
<%= tipasa_button "agenda", class: "help-button" do %>
  <%= lucide_icon "circle-help" %>
<% end %>
```

A tour started with `?tour=` plays even if it was completed. Add `&resume=1` to reopen it at the step where the user closed it.

Closing a tour (with the ×, Escape, or by replaying another one) counts as completing it, the same as finishing it. Leaving the page doesn't.

## Configuration

```ruby
# config/initializers/tipasa.rb
Tipasa.configure do |config|
  # Who takes the tour on this request; nil when nobody is signed in.
  config.current_owner = ->(c) { c.current_user || c.current_admin_user }

  # Defaults to ActionController::Base, so your before_actions don't run on the tour endpoints.
  # config.parent_controller = "ApplicationController"

  # Button and hint language (en and es ship with the gem); nil follows I18n.locale.
  # config.locale = :es

  # config.tours_path = Rails.root.join("config/tours")
end
```

To change the text, override the `tipasa.*` keys in your locale files. See [config/locales/en.yml](config/locales/en.yml).

## Owners and completions

Owners are polymorphic: any model can take tours.

```ruby
class User < ApplicationRecord
  include Tipasa::Owner
end

user.completed_tour?("agenda")  # => true / false
user.pending_tours              # active tours this user may see and hasn't completed
user.tipasa_completions         # Tipasa::Completion records (owner, tour_slug, timestamps)
```

`for: [AdminUser]` limits a tour to those classes. Everyone else, including anonymous visitors, gets a 404 for it, and it's left out of `pending_tours`. A tour without `for:` is visible to everyone, signed in or not. Only signed-in owners can complete one.

Completions are keyed by slug, so renaming a tour's file resets who has completed it.

## Endpoints

Mounted where the installer put it (`/tours` by default):

- `GET /tours/:slug`: the tour as JSON, plus `completed` for the current owner.
- `POST /tours/:slug/complete`: records the completion (401 without an owner).

## Styling

`tipasa.css` imports driver.js's styles and adds the step counter, the "waiting" hint and the pulse. Theme it with `--tipasa-accent` and the `--driver-*` variables, or target `.tipasa-popover`.

## Development

```bash
bundle install
bundle exec rspec
bin/rubocop
RAILS_VERSION="~> 7.2.0" bundle update && bundle exec rspec   # other Rails versions
```

## Releasing

Releases are managed by [release-please](https://github.com/googleapis/release-please). PR titles must follow [Conventional Commits](https://www.conventionalcommits.org) (`feat:`, `fix:`, `feat!:`). Merging the release PR tags the version and publishes the gem and the npm package with the same version number, using trusted publishing on rubygems.org and npmjs.com.

## License

MIT. driver.js is MIT too, so commercial apps need no extra license.
