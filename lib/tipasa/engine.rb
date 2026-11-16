require "tipasa/helper"

module Tipasa
  class Engine < ::Rails::Engine
    isolate_namespace Tipasa

    initializer "tipasa.helper" do
      ActiveSupport.on_load(:action_view) { include Tipasa::Helper }
    end
  end
end
