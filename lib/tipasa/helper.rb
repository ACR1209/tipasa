module Tipasa
  module Helper
    LABELS = %i[next back done close waiting progress].freeze

    def tipasa_button(slug, **options, &block)
      label = I18n.t("tipasa.replay", locale: Tipasa.locale)
      data = tipasa_data(slug, manual: true).merge(action: "tipasa#replay").merge(options.delete(:data) || {})
      content = block ? capture(&block) : "?"
      tag.button(content, type: "button", title: label, aria: { label: }, data:, **options)
    end

    def tipasa_autostart
      return if params[:tour].blank?

      tag.div(data: tipasa_data(params[:tour], replay: true, resume: params[:resume].present?))
    end

    private

    def tipasa_data(slug, **values)
      labels = LABELS.to_h { |key| [ key, I18n.t("tipasa.#{key}", locale: Tipasa.locale) ] }
      {
        controller: "tipasa",
        tipasa_slug_value: slug,
        tipasa_url_value: tipasa.tour_path(slug),
        tipasa_complete_url_value: tipasa.complete_tour_path(slug),
        tipasa_labels_value: labels.to_json
      }.merge(values.transform_keys { |key| :"tipasa_#{key}_value" })
    end
  end
end
