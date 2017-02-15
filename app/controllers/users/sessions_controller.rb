class Users::SessionsController < Devise::SessionsController
  after_filter :after_login, only: :create

  private

    def after_sign_in_path_for(resource)
      if current_user.poll_officer?
        new_officing_booth_path
      elsif !verifying_via_email? && resource.show_welcome_screen?
        welcome_path
      else
        super
      end
    end

    def after_login
      log_event("login", "successful_login")
    end

    def after_sign_out_path_for(resource)
      super
    end

    def verifying_via_email?
      return false unless resource.present?
      stored_path = session[stored_location_key_for(resource)] || ""
      stored_path[0..5] == "/email"
    end

end
