class DoubleConfirmationsController < ApplicationController
    skip_authorization_check

    def no_phone

    end

    def user_blocked

    end

    def request_access_key
        
    end

    def new_password_sent
        unless current_user.blank?
            new_access_key_length = 10
            new_access_key = "aAbcdeEfghiJkmnpqrstuUvwxyz23456789$!".split("").sample(10).join("")
            encrypted_access_key = encrypt_access_key(new_access_key)
            current_user.update(access_key_generated: encrypted_access_key)
            current_user.update(access_key_generated_at: Time.now)
            self.send_sms(new_access_key)
            redirect_to request_access_key_double_confirmations_path, notice: I18n.t("admin.double_verification.new_password_sent")
        end
    end

    def send_sms(access_key)
        SMSApi.new.sms_deliver(current_user.confirmed_phone, access_key)
    end


    def request_post_access_key
        unless current_user.blank?
            access_count= (current_user.access_key_tried.to_i) + 1
            access_key_inserted_encrypted = encrypt_access_key(params[:access_key])
            current_user.update(access_key_inserted: access_key_inserted_encrypted)
            if current_user.access_key_tried < 3 #&& usuario no bloqueado
                current_user.update(access_key_tried: access_count)
                redirect_to request_access_key_double_confirmations_path, alert: I18n.t("admin.double_verification.access_key_error")
            else
                redirect_to user_blocked_double_confirmations_path
            end
        end
    end


    def encrypt_access_key(access_key)
       unless current_user.blank? 
            Criptografia.new.encrypt(access_key)
        end
    end

     def decrypt_access_key(encrypted_access_key)
        begin
            unless current_user.blank? 
                Criptografia.new.decrypt(encrypted_access_key.to_s)
            end
        rescue
            current_user.update(access_key_generated_at: nil)
        end
     end

    def access_key_inserted_correct?
        decrypt_access_key(current_user.access_key_generated.to_s) == decrypt_access_key(current_user.access_key_inserted.to_s)
    end
    
end
