class DoubleConfirmationsController < ApplicationController

    def no_phone
    end

    def user_blocked
    end

    def request_access_key

    end

    def new_password_sent
    end

    def encrypt_access_key
        access_key=Criptografia.new.encrypt(current_user.username,params[:access_key_inserted])
    end

    def decrypt_access_key
        access_key=Criptografia.new.decrypt(current_user.username,params[:access_key_inserted])
    end
end
