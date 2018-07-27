App.Globalize =

  display_locale: (form, locale) ->
    form.find(".js-globalize-locale-link").each ->
      if $(this).data("locale") == locale
        $(this).show()
        App.Globalize.highlight_locale(form, $(this))
      form.find(".js-globalize-locale option:selected").removeAttr("selected");
      return

  display_translations: (form, locale) ->
    form.find(".js-globalize-attribute").each ->
      if $(this).data("locale") == locale
        $(this).show()
      else
        $(this).hide()
      #$('.js-delete-language').hide()
      form.find('.js-delete-language').hide()
      #console.log(this)
      #$(this).find('#delete-' + locale).show()
      form.find('#delete-' + locale).show()

  highlight_locale: (form, element) ->
    form.find('.js-globalize-locale-link').removeClass('is-active');
    element.addClass('is-active');

  remove_language: (form, locale) ->
    form.find(".js-globalize-attribute[data-locale=" + locale + "]").val('').hide()
    form.find(".js-globalize-locale-link[data-locale=" + locale + "]").hide()
    next = form.find(".js-globalize-locale-link:visible").first()
    App.Globalize.highlight_locale(form, next)
    App.Globalize.display_translations(form, next.data("locale"))
    form.find("#delete_translations_" + locale).val(1)

  initialize: ->
    $('.translatable-form').each ->
      form = $(this)
      form.find('.js-globalize-locale').on 'change', ->
        App.Globalize.display_translations(form, $(this).val())
        App.Globalize.display_locale(form, $(this).val())

      form.find('.js-globalize-locale-link').on 'click', ->
        locale = $(this).data("locale")
        App.Globalize.display_translations(form, locale)
        App.Globalize.highlight_locale(form, $(this))

      form.find('.js-delete-language').on 'click', ->
        locale = $(this).data("locale")
        $(this).hide()
        App.Globalize.remove_language(form, locale)
