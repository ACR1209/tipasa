require "rails/generators"

module Tipasa
  module Generators
    # rails g tipasa:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "initializer.rb", "config/initializers/tipasa.rb"
      end

      def create_tours_folder
        empty_directory "config/tours"
      end

      def mount_engine
        route 'mount Tipasa::Engine, at: "/tours"'
      end

      def copy_migrations
        rake "tipasa:install:migrations"
      end
    end
  end
end
