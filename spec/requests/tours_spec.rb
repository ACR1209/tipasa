RSpec.describe "Tours endpoints" do
  let(:user) { User.create! }
  let(:admin) { AdminUser.create! }

  describe "GET /tours/:slug" do
    it "serves the tour to anonymous visitors" do
      get "/tours/welcome"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("slug" => "welcome", "name" => "Welcome", "completed" => false)
      expect(response.parsed_body["steps"].pluck("id")).to eq(%w[hello menu])
    end

    it "says whether the signed-in owner completed it" do
      sign_in(user)
      user.tipasa_completions.create!(tour_slug: "welcome")

      get "/tours/welcome"

      expect(response.parsed_body["completed"]).to be(true)
    end

    it "keeps completions apart per owner type" do
      sign_in(admin)
      User.create!(id: admin.id).tipasa_completions.create!(tour_slug: "welcome")

      get "/tours/welcome"

      expect(response.parsed_body["completed"]).to be(false)
    end

    it "404s for unknown, inactive and path-traversal slugs" do
      get "/tours/nope"
      expect(response).to have_http_status(:not_found)

      get "/tours/retired"
      expect(response).to have_http_status(:not_found)

      get "/tours/..%2F..%2Fconfig%2Fdatabase"
      expect(response).to have_http_status(:not_found)
    end

    context "with a `for:` audience" do
      it "serves it to that owner class" do
        sign_in(admin)
        get "/tours/admin"
        expect(response).to have_http_status(:ok)
      end

      it "404s for other owner classes and anonymous visitors" do
        get "/tours/admin"
        expect(response).to have_http_status(:not_found)

        sign_in(user)
        get "/tours/admin"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /tours/:slug/complete" do
    it "records the completion once" do
      sign_in(user)

      2.times { post "/tours/welcome/complete", as: :json }

      expect(response).to have_http_status(:ok)
      expect(user.tipasa_completions.pluck(:tour_slug)).to eq(%w[welcome])
    end

    it "is unauthorized without an owner" do
      post "/tours/welcome/complete", as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(Tipasa::Completion.count).to eq(0)
    end

    it "can't complete a tour the owner can't see" do
      sign_in(user)

      post "/tours/admin/complete", as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
