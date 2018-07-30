require 'rails_helper'

feature 'Cards' do

  background do
    admin = create(:administrator).user
    login_as(admin)
  end

  scenario "Create", :js do
    visit admin_homepage_path
    click_link "Create card"

    fill_in "widget_card_label_en", with: "Card label"
    fill_in "widget_card_title_en", with: "Card text"
    fill_in "widget_card_description_en", with: "Card description"
    fill_in "widget_card_link_text_en", with: "Link text"
    fill_in "widget_card_link_url", with: "consul.dev"
    attach_image_to_card
    click_button "Create card"

    expect(page).to have_content "Success"
    expect(page).to have_css(".homepage-card", count: 1)

    card = Widget::Card.last
    within("#widget_card_#{card.id}") do
      expect(page).to have_content "Card label"
      expect(page).to have_content "Card text"
      expect(page).to have_content "Card description"
      expect(page).to have_content "Link text"
      expect(page).to have_content "consul.dev"
      expect(page).to have_link("Show image", href: card.image_url(:large))
    end
  end

  scenario "Index" do
    3.times { create(:widget_card) }

    visit admin_homepage_path

    expect(page).to have_css(".homepage-card", count: 3)

    cards = Widget::Card.all
    cards.each do |card|
      expect(page).to have_content card.title
      expect(page).to have_content card.description
      expect(page).to have_content card.link_text
      expect(page).to have_content card.link_url
      expect(page).to have_link("Show image", href: card.image_url(:large))
    end
  end

  scenario "Edit" do
    card = create(:widget_card)

    visit admin_homepage_path

    within("#widget_card_#{card.id}") do
      click_link "Edit"
    end

    fill_in "widget_card_label_en", with: "Card label updated"
    fill_in "widget_card_title_en", with: "Card text updated"
    fill_in "widget_card_description_en", with: "Card description updated"
    fill_in "widget_card_link_text_en", with: "Link text updated"
    fill_in "widget_card_link_url", with: "consul.dev updated"
    click_button "Save card"

    expect(page).to have_content "Updated"

    expect(page).to have_css(".homepage-card", count: 1)
    within("#widget_card_#{Widget::Card.last.id}") do
      expect(page).to have_content "Card label updated"
      expect(page).to have_content "Card text updated"
      expect(page).to have_content "Card description updated"
      expect(page).to have_content "Link text updated"
      expect(page).to have_content "consul.dev updated"
    end
  end

  scenario "Remove", :js do
    card = create(:widget_card)

    visit admin_homepage_path

    within("#widget_card_#{card.id}") do
      accept_confirm do
        click_link "Delete"
      end
    end

    expect(page).to have_content "Removed"
    expect(page).to have_css(".homepage-card", count: 0)
  end

  context "Header Card" do

    scenario "Create" do
      visit admin_homepage_path
      click_link "Create header"

      fill_in "widget_card_label_en", with: "Header label"
      fill_in "widget_card_title_en", with: "Header text"
      fill_in "widget_card_description_en", with: "Header description"
      fill_in "widget_card_link_text_en", with: "Link text"
      fill_in "widget_card_link_url", with: "consul.dev"
      click_button "Create header"

      expect(page).to have_content "Success"

      within("#header") do
        expect(page).to have_css(".homepage-card", count: 1)
        expect(page).to have_content "Header label"
        expect(page).to have_content "Header text"
        expect(page).to have_content "Header description"
        expect(page).to have_content "Link text"
        expect(page).to have_content "consul.dev"
      end

      within("#cards") do
        expect(page).to have_css(".homepage-card", count: 0)
      end
    end

  end

  pending "add image expectactions"

  def attach_image_to_card
    click_link "Add image"
    image_input = all(".image").last.find("input[type=file]", visible: false)
    attach_file(
      image_input[:id],
      Rails.root.join('spec/fixtures/files/clippy.jpg'),
      make_visible: true)
    expect(page).to have_field('widget_card_image_attributes_title', with: "clippy.jpg")
  end

  context "Translations" do

    let(:card) { create(:widget_card, title_en: "Title in English",
                                      title_es: "Título en Español",
                                      description_en: "Description in English",
                                      description_es: "Descripción en Español") }

    before do
      @edit_card_url = edit_admin_widget_card_path(card)
    end

    scenario "Add a translation", :js do
      visit @edit_card_url

      select "Français", from: "translation_locale"
      fill_in 'widget_card_title_fr', with: 'Titre en Français'
      fill_in 'widget_card_description_fr', with: 'Description en Français'

      click_button 'Save card'

      visit @edit_card_url
      expect(page).to have_field('widget_card_description_en', with: 'Description in English')

      click_link "Español"
      expect(page).to have_field('widget_card_description_es', with: 'Descripción en Español')

      click_link "Français"
      expect(page).to have_field('widget_card_description_fr', with: 'Description en Français')
    end

    scenario "Update a translation", :js do
      visit @edit_card_url

      click_link "Español"
      fill_in 'widget_card_description_es', with: 'Descripción correcta en Español'

      click_button 'Save card'

      visit root_path

      within("#widget_card_#{card.id}") do
        expect(page).to have_content("Description in English")
      end

      select('Español', from: 'locale-switcher')

      within("#widget_card_#{card.id}") do
        expect(page).to have_content('Descripción correcta en Español')
      end
    end

    scenario "Remove a translation", :js do

      visit @edit_card_url

      click_link "Español"
      click_link "Remove language"

      expect(page).not_to have_link "Español"

      click_button "Save card"
      visit @edit_card_url
      expect(page).not_to have_link "Español"
    end

    context "Globalize javascript interface" do

      scenario "Highlight current locale", :js do
        visit @edit_card_url

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "English"

        select('Español', from: 'locale-switcher')

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "Español"
      end

      scenario "Highlight selected locale", :js do
        visit @edit_card_url

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "English"

        click_link "Español"

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "Español"
      end

      scenario "Show selected locale form", :js do
        visit @edit_card_url

        expect(page).to have_field('widget_card_description_en', with: 'Description in English')

        click_link "Español"

        expect(page).to have_field('widget_card_description_es', with: 'Descripción en Español')
      end

      scenario "Select a locale and add it to the card form", :js do
        visit @edit_card_url

        select "Français", from: "translation_locale"

        expect(page).to have_link "Français"

        click_link "Français"

        expect(page).to have_field('widget_card_description_fr')
      end
    end
  end
end
