require_relative "lib/tipasa/version"

Gem::Specification.new do |spec|
  spec.name        = "tipasa"
  spec.version     = Tipasa::VERSION
  spec.authors     = [ "ACR1209" ]
  spec.homepage    = "https://github.com/ACR1209/tipasa"
  spec.summary     = "Guided product tours for Rails apps, written in YAML."
  spec.description = "A Rails engine that serves product tours defined in config/tours/*.yml, records who completed them, and ships a Stimulus controller built on driver.js."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
end
