module Tipasa
  class ApplicationController < Tipasa.parent_controller.constantize
    protect_from_forgery with: :exception
  end
end
