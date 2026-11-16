module Tipasa
  class Completion < ApplicationRecord
    belongs_to :owner, polymorphic: true

    validates :tour_slug, presence: true, uniqueness: { scope: %i[owner_type owner_id] }
  end
end
