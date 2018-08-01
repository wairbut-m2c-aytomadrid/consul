require 'rails_helper'

feature "Admin Notifications" do

  background do
    admin = create(:administrator)
    login_as(admin.user)
    create(:budget)
  end

  context "Show" do
    scenario "Valid Admin Notification" do
      notification = create(:admin_notification, title: 'Notification title',
                                                 body: 'Notification body',
                                                 link: 'https://www.decide.madrid.es/vota',
                                                 segment_recipient: :all_users)

      visit admin_admin_notification_path(notification)

      expect(page).to have_content('Notification title')
      expect(page).to have_content('Notification body')
      expect(page).to have_content('https://www.decide.madrid.es/vota')
      expect(page).to have_content('All users')
    end

    scenario "Notification with invalid segment recipient" do
      invalid_notification = create(:admin_notification)
      invalid_notification.update_attribute(:segment_recipient, 'invalid_segment')

      visit admin_admin_notification_path(invalid_notification)

      expect(page).to have_content("Recipients user segment is invalid")
    end
  end

  context "Index" do
    scenario "Valid Admin Notifications" do
      draft = create(:admin_notification, segment_recipient: :all_users, title: 'Not yet sent')
      sent = create(:admin_notification, :sent, segment_recipient: :administrators,
                                                title: 'Sent one')

      visit admin_admin_notifications_path

      expect(page).to have_css(".admin_notification", count: 2)

      within("#admin_notification_#{draft.id}") do
        expect(page).to have_content('Not yet sent')
        expect(page).to have_content('All users')
        expect(page).to have_content('Draft')
      end

      within("#admin_notification_#{sent.id}") do
        expect(page).to have_content('Sent one')
        expect(page).to have_content('Administrators')
        expect(page).to have_content(I18n.l(Date.current))
      end
    end

    scenario "Notifications with invalid segment recipient" do
      invalid_notification = create(:admin_notification)
      invalid_notification.update_attribute(:segment_recipient, 'invalid_segment')

      visit admin_admin_notifications_path

      expect(page).to have_content("Recipients user segment is invalid")
    end
  end

  scenario "Create" do
    visit admin_admin_notifications_path
    click_link "New notification"

    fill_in_admin_notification_form(segment_recipient: 'Proposal authors',
                                    title: 'This is a title',
                                    body: 'This is a body',
                                    link: 'http://www.dummylink.dev')

    click_button "Create notification"

    expect(page).to have_content "Notification created successfully"
    expect(page).to have_content "Proposal authors"
    expect(page).to have_content "This is a title"
    expect(page).to have_content "This is a body"
    expect(page).to have_content "http://www.dummylink.dev"
  end

  context "Update" do
    scenario "A draft notification can be updated" do
      notification = create(:admin_notification)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        click_link "Edit"
      end


      fill_in_admin_notification_form(segment_recipient: 'All users',
                                      title: 'Other title',
                                      body: 'Other body',
                                      link: '')

      click_button "Update notification"

      expect(page).to have_content "Notification updated successfully"
      expect(page).to have_content "All users"
      expect(page).to have_content "Other title"
      expect(page).to have_content "Other body"
      expect(page).not_to have_content "http://www.dummylink.dev"
    end

    scenario "Sent notification can not be updated" do
      notification = create(:admin_notification, :sent)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        expect(page).not_to have_link("Edit")
      end
    end
  end

  context "Destroy" do
    scenario "A draft notification can be destroyed" do
      notification = create(:admin_notification)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        click_link "Delete"
      end

      expect(page).to have_content "Notification deleted successfully"
      expect(page).to have_css(".notification", count: 0)
    end

    scenario "Sent notification can not be destroyed" do
      notification = create(:admin_notification, :sent)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        expect(page).not_to have_link("Delete")
      end
    end
  end

  context "Visualize" do
    scenario "A draft notification can be previewed" do
      notification = create(:admin_notification, segment_recipient: :administrators)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        click_link "Preview"
      end

      expect(page).to have_content "This is how the users will see the notification:"
      expect(page).to have_content "Administrators (1 users will be notified)"
    end

    scenario "A sent notification can be viewed" do
      notification = create(:admin_notification, :sent, recipients_count: 7,
                                                        segment_recipient: :administrators)

      visit admin_admin_notifications_path
      within("#admin_notification_#{notification.id}") do
        click_link "View"
      end

      expect(page).to have_content "This is how the users see the notification:"
      expect(page).to have_content "Administrators (7 users got notified)"
    end
  end

  scenario 'Errors on create' do
    visit new_admin_admin_notification_path

    click_button "Create notification"

    expect(page).to have_content error_message
  end

  scenario "Errors on update" do
    notification = create(:admin_notification)
    visit edit_admin_admin_notification_path(notification)

    fill_in :admin_notification_title_en, with: ''
    click_button "Update notification"

    expect(page).to have_content error_message
  end

  context "Send notification", :js do
    scenario "A draft Admin notification can be sent", :js do
      2.times { create(:user) }
      notification = create(:admin_notification, segment_recipient: :all_users)
      total_users = notification.list_of_recipients.count
      confirm_message = "Are you sure you want to send this notification to #{total_users} users?"

      visit admin_admin_notification_path(notification)

      accept_confirm { accept_confirm { click_link "Send notification" }}

      expect(page).to have_content "Notification sent successfully"

      User.all.each do |user|
        expect(user.notifications.count).to eq(1)
      end
    end

    scenario "A sent Admin notification can not be sent", :js do
      notification = create(:admin_notification, :sent)

      visit admin_admin_notification_path(notification)

      expect(page).not_to have_link("Send")
    end

    scenario "Admin notification with invalid segment recipient cannot be sent", :js do
      invalid_notification = create(:admin_notification)
      invalid_notification.update_attribute(:segment_recipient, 'invalid_segment')
      visit admin_admin_notification_path(invalid_notification)

      expect(page).not_to have_link("Send")
    end
  end

  scenario "Select list of users to send notification" do
    UserSegments.segments.each do |user_segment|
      segment_recipient = I18n.t("admin.segment_recipient.#{user_segment}")

      visit new_admin_admin_notification_path

      fill_in_admin_notification_form(segment_recipient: segment_recipient)
      click_button "Create notification"

      expect(page).to have_content(I18n.t("admin.segment_recipient.#{user_segment}"))
    end
  end

  context "Translations" do

    let(:notification) { create(:admin_notification,
                                title_en: 'Title in English',
                                body_en:  'Body in English',
                                title_es: 'Título en Español',
                                body_es:  'Texto en Español',
                                link: 'https://www.decide.madrid.es/vota') }

    before do
      @edit_notification_url = edit_admin_admin_notification_path(notification)
    end

    scenario "Add a translation", :js do
      visit @edit_notification_url

      select "Français", from: "translation_locale"
      fill_in 'admin_notification_title_fr', with: 'Titre en Français'
      fill_in 'admin_notification_body_fr', with: 'Texte en Français'

      click_button 'Update notification'

      visit @edit_notification_url
      expect(page).to have_field('admin_notification_body_en', with: 'Body in English')

      click_link "Español"
      expect(page).to have_field('admin_notification_body_es', with: 'Texto en Español')

      click_link "Français"
      expect(page).to have_field('admin_notification_body_fr', with: 'Texte en Français')
    end

    scenario "Update a translation", :js do
      visit @edit_notification_url

      click_link "Español"
      fill_in 'admin_notification_title_es', with: 'Título correcto en Español'

      click_button 'Update notification'

      select('Español', from: 'locale-switcher')

      expect(page).to have_content('Título correcto en Español')
    end

    scenario "Remove a translation", :js do

      visit @edit_notification_url

      click_link "Español"
      click_link "Remove language"

      expect(page).not_to have_link "Español"

      click_button "Update notification"
      visit @edit_notification_url
      expect(page).not_to have_link "Español"
    end

    context "Globalize javascript interface" do

      scenario "Highlight current locale", :js do
        visit @edit_notification_url

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "English"

        select('Español', from: 'locale-switcher')

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "Español"
      end

      scenario "Highlight selected locale", :js do
        visit @edit_notification_url

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "English"

        click_link "Español"

        expect(find("a.js-globalize-locale-link.is-active")).to have_content "Español"
      end

      scenario "Show selected locale form", :js do
        visit @edit_notification_url

        expect(page).to have_field('admin_notification_body_en', with: 'Body in English')

        click_link "Español"

        expect(page).to have_field('admin_notification_body_es', with: 'Texto en Español')
      end

      scenario "Select a locale and add it to the notification form", :js do
        visit @edit_notification_url

        select "Français", from: "translation_locale"

        expect(page).to have_link "Français"

        click_link "Français"

        expect(page).to have_field('admin_notification_body_fr')
      end
    end
  end
end
