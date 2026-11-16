source "https://rubygems.org"

gemspec

gem "rails", ENV.fetch("RAILS_VERSION", ">= 7.1")
gem "sqlite3"
gem "puma"
gem "rspec-rails"
gem "rubocop-rails-omakase", require: false

# json 3 dropped the quirks_mode keyword ActiveSupport 7.x still passes to JSON.generate.
gem "json", "< 3" if ENV["RAILS_VERSION"].to_s.match?(/\b7\./)
