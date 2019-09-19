class Users::SessionsController < Devise::SessionsController
  require "ipaddr"
  prepend_before_action :check_recaptcha, only: [:create]

  after_action :after_login, only: :create

  def show_recaptcha
    render json: { recaptcha: show_recaptcha_for?(params[:login]) }
  end

  private

    def check_recaptcha
      if Setting["feature.captcha"] && show_recaptcha_for?(params[:user][:login])
        unless verify_recaptcha
          flash.discard
          redirect_to new_user_session_path, alert: I18n.t("recaptcha.errors.verification_failed")
        end
      end
    end

    def show_recaptcha_for?(login)
      user = User.find_by_username(login) || User.find_by_email(login)
      return false unless user.present?
      user.exceeded_failed_login_attempts?
    end

    def after_sign_in_path_for(resource)
      if false #current_user.poll_officer? && current_user.has_poll_active?
        if current_user.poll_officer.letter_officer?
          new_officing_letter_path
        end
      elsif !verifying_via_email? && resource.show_welcome_screen?
        welcome_path
      else
        if user_admin? && ip_out_of_internal_red?
          if phone_number_present?
            double_confimation_needed
          else
            #sign_out
            no_phone_double_confirmations_path
          end
        else
          super
        end
      end
    end

    def user_admin?
      current_user.try(:administrator?)
    end

    def phone_number_present?
      !current_user.try(:phone_number).blank? && !current_user.try(:confirmed_phone).blank?  && (current_user.phone_number == current_user.confirmed_phone)
    end

    def ip_out_of_internal_red?
      current_ip = current_user.current_sign_in_ip.to_i
      # low = IPAddr.new("10.90.0.0").to_i
      # high = IPAddr.new("10.90.255.255").to_i
      low = IPAddr.new("0.0.0.0").to_i
      high = IPAddr.new("255.255.255.255").to_i
      (low..high)===current_ip
    end

    def double_confimation_needed
      unless required_new_password?
        request_access_key_double_confirmations_path
      else
        generate_new_access_key
      end
    end

    def required_new_password?
      if current_user.access_key_generated_at.present?
        date1= Time.zone.now
        date2= current_user.access_key_generated_at
        (date1.year * 12 + date1.month) - (date2.year * 12 + date2.month) > Setting.find_by(key: "months_to_double_verification").try(:value).to_i
      end
    end

    def generate_new_access_key
      xxx
      #new_access_key_length = 10
      ##new_access_key = Devise.friendly_token.first(new_access_key_length)
      #new_access_key = "aAbcdeEfghiJkmnpqrstuUvwxyz23456789$!".split("").sample(10).join("")
      #current_user.access_key_generated = new_access_key
    end

    def after_login
      log_event("login", "successful_login")
    end

    def after_sign_out_path_for(resource)
      request.referer.present? && !request.referer.match("management") ? request.referer : super
    end

    def verifying_via_email?
      return false if resource.blank?
      stored_path = session[stored_location_key_for(resource)] || ""
      stored_path[0..5] == "/email"
    end
end
