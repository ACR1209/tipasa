Tipasa.configure do |config|
  # Who takes the tour on this request; nil when nobody is signed in.
  # Several account models? config.current_owner = ->(c) { c.current_user || c.current_admin_user }
  config.current_owner = ->(controller) { controller.try(:current_user) }

  # Inherit from your ApplicationController to run its filters (auth, locale, paper_trail...) on the tour endpoints.
  # config.parent_controller = "ApplicationController"

  # Locale for the buttons and hints (en and es ship with the gem); nil follows I18n.locale.
  # config.locale = :es

  # config.tours_path = Rails.root.join("config/tours")
end
