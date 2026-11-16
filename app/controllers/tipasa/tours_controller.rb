module Tipasa
  class ToursController < ApplicationController
    before_action :set_tour

    def show
      completed = owner.present? && Completion.exists?(owner:, tour_slug: @tour.slug)
      render json: @tour.as_json.merge(completed:)
    end

    def complete
      return head :unauthorized unless owner

      begin
        Completion.find_or_create_by!(owner:, tour_slug: @tour.slug)
      rescue ActiveRecord::RecordNotUnique
        # A double request raced us to it; the tour is completed either way.
      end

      render json: { success: true }
    end

    private

    def set_tour
      @tour = Tour.find(params[:slug])
      head :not_found unless @tour&.active? && @tour.visible_to?(owner)
    end

    def owner
      return @owner if defined?(@owner)

      @owner = Tipasa.current_owner.call(self)
    end
  end
end
