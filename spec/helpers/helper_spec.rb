RSpec.describe "View helpers", type: :request do
  def data(selector, attribute)
    Nokogiri::HTML(response.body).at(selector)&.[]("data-tipasa-#{attribute}")
  end

  it "renders the replay button with engine URLs and labels" do
    get "/page"

    button = Nokogiri::HTML(response.body).at("button")
    expect(button["class"]).to eq("help")
    expect(button["aria-label"]).to eq("Show the tour")
    expect(button["data-action"]).to eq("tipasa#replay")
    expect(data("button", "url-value")).to eq("/tours/welcome")
    expect(data("button", "complete-url-value")).to eq("/tours/welcome/complete")
    expect(data("button", "manual-value")).to eq("true")
    expect(JSON.parse(data("button", "labels-value"))).to include("next" => "Next", "progress" => "Step %{current} of %{total}")
  end

  it "autostarts only when ?tour= is present" do
    get "/page"
    expect(data("div[data-controller=tipasa]", "slug-value")).to be_nil

    get "/page", params: { tour: "welcome", resume: "1" }
    expect(data("div[data-controller=tipasa]", "slug-value")).to eq("welcome")
    expect(data("div[data-controller=tipasa]", "resume-value")).to eq("true")
  end

  it "uses the configured locale" do
    allow(Tipasa).to receive(:locale).and_return(:es)

    get "/page"

    expect(JSON.parse(data("button", "labels-value"))).to include("next" => "Siguiente", "progress" => "Paso %{current} de %{total}")
  end
end
