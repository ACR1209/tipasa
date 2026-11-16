module Tipasa
  # Include in every model that takes tours (User, AdminUser...).
  module Owner
    extend ActiveSupport::Concern

    included do
      has_many :tipasa_completions, class_name: "Tipasa::Completion", as: :owner, dependent: :delete_all
    end

    def completed_tour?(slug)
      tipasa_completions.exists?(tour_slug: slug.to_s)
    end

    # Active tours this owner may see and hasn't completed.
    def pending_tours
      done = tipasa_completions.pluck(:tour_slug)
      Tipasa::Tour.all.select { |tour| tour.active? && tour.visible_to?(self) && done.exclude?(tour.slug) }
    end
  end
end
