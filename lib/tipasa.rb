require "tipasa/version"
require "tipasa/engine"

module Tipasa
  mattr_accessor :current_owner, default: ->(controller) { controller.try(:current_user) }

  mattr_accessor :parent_controller, default: "ActionController::Base"

  mattr_accessor :locale

  mattr_writer :tours_path

  def self.tours_path
    @@tours_path || Rails.root.join("config/tours")
  end

  def self.configure
    yield self
  end
end
