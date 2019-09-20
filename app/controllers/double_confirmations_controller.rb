class DoubleConfirmationsController < ApplicationController
    skip_authorization_check

    def no_phone

    end

    def user_blocked

    end

    def request_access_key
        
    end

    def request_post_access_key
        unless current_user.blank?
            access_count = current_user.access_key_tried.to_i
            access_count= access_count + 1
            access_key_inserted_encrypted = encrypt_access_key(params[:access_key])
            current_user.update(access_key_inserted: access_key_inserted_encrypted)
            current_user.update(access_key_tried: access_count)
        end
    end

    def new_password_sent
        unless current_user.blank? 
            new_access_key_length = 10
            new_access_key = "aAbcdeEfghiJkmnpqrstuUvwxyz23456789$!".split("").sample(10).join("")
            encrypted_access_key = encrypt_access_key(new_access_key)
            current_user.update(access_key_generated: encrypted_access_key)
            current_user.update(access_key_generated_at: Time.now)
        end
    end

    def encrypt_access_key(access_key)
       unless current_user.blank? 
            Criptografia.new.encrypt(try(:current_user).username,access_key)
        end
    end

     def decrypt_access_key(encrypted_access_key)
        unless current_user.blank? 
            Criptografia.new.decrypt(current_user.username,encrypted_access_key)
        end
     end
end
