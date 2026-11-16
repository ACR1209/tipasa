RSpec.describe Tipasa::Owner do
  let(:user) { User.create! }
  let(:admin) { AdminUser.create! }

  it "lists active tours the owner may see and hasn't completed" do
    expect(user.pending_tours.map(&:slug)).to eq(%w[welcome])
    expect(admin.pending_tours.map(&:slug)).to eq(%w[admin welcome])

    admin.tipasa_completions.create!(tour_slug: "admin")

    expect(admin.pending_tours.map(&:slug)).to eq(%w[welcome])
    expect(admin.completed_tour?(:admin)).to be(true)
    expect(user.completed_tour?("admin")).to be(false)
  end

  it "deletes completions with the owner" do
    user.tipasa_completions.create!(tour_slug: "welcome")

    expect { user.destroy }.to change(Tipasa::Completion, :count).by(-1)
  end
end
