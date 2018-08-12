module TranslatableFormHelper
  def translatable_form_for(record, options = {})
    object = record.is_a?(Array) ? record.last : record

    form_for(record, options.merge(builder: TranslatableFormBuilder)) do |f|

      object.globalize_locales.each do |locale|
        concat translation_enabled_tag(locale, enable_locale?(object, locale))
      end

      yield(f)
    end
  end
end

class TranslatableFormBuilder < FoundationRailsHelper::FormBuilder

  def translatable_text_field(method, options = {})
    translatable_field(:text_field, method, options)
  end
  def translatable_text_area(method, options = {})
    translatable_field(:text_area, method, options)
  end

  private

    def translatable_field(field_type, method, options = {})
      @template.capture do
        @object.globalize_locales.each do |locale|
          Globalize.with_locale(locale) do
            final_options = options.merge(
              class: (options.fetch(:class, "") + " js-globalize-attribute"),
              style: @template.display_translation?(locale),
              data:  options.fetch(:data, {}).merge(locale: locale),
              label_options: {
                class: (options.fetch(:class, "") + " js-globalize-attribute"),
                style: @template.display_translation?(locale),
                data:  (options.dig(:label_options, :data) || {}) .merge(locale: locale)
              }
            )

            @template.concat send(field_type, "#{method}_#{locale}", final_options)
          end
        end
      end
    end

  #render_translated_fields(@object.globalize_locales, visible_locale: neutral(I18n.current))
  def render_translated_fields(locales, visible_locale:)
  end

  #render_translation_fields(@object) do |locale|
    #opts = options.merge()
    #text_field(method + .. , opts)
  #end
  def render_translation_fields(object)
    @template.capture do
      object.globalize_locales.each do |locale|
        Globalize.with_locale(locale) do
          @template.concat yield(locale)
        end
      end
    end
  end

  #def div_radio_button(method, tag_value, options = {})
    #@template.content_tag(:div,
      #@template.radio_button(
        #@object_name, method, tag_value, objectify_options(options)
      #)
    #)
  #end
end
