ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"
require "rspec/rails"

# The test database lives in memory: build it from the gem's own migration plus the dummy owners.
ActiveRecord::Migration.verbose = false
require_relative "../db/migrate/20261115000000_create_tipasa_completions"
CreateTipasaCompletions.migrate(:up)
ActiveRecord::Schema.define do
  create_table(:users) { |t| t.string :name }
  create_table(:admin_users) { |t| t.string :name }
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  # Signs someone in, the way the host's config.current_owner lambda would find them.
  config.include(Module.new do
    def sign_in(owner)
      allow(Tipasa).to receive(:current_owner).and_return(->(_controller) { owner })
    end
  end)
end
