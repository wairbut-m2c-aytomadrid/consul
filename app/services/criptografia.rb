class Criptografia
    def initialize
        @iterations = 19
        @salt_bytes = [-87,-101,-56,50,86,53,-29, 3]
    end

    def encrypt(passkey,str)
        cipher = OpenSSL::Cipher::Cipher.new("DES")
        cipher.encrypt
        cipher.pkcs5_keyivgen passkey, @salt_bytes.pack('C*').force_encoding('utf-8'),@iterations, 'MD5'
        encrypted_account_number =  cipher.update(str)
        encrypted_account_number << cipher.final
        Base64.encode64(encrypted_account_number )
    end

    def decrypt(passkey,str)
        uncipher = OpenSSL::Cipher.new('DES')
        uncipher.decrypt
        uncipher.pkcs5_keyivgen passkey, @salt_bytes.pack('C*').force_encoding('utf-8'),@iterations
        decrypted_str =  uncipher.update(Base64.decode64(str))
        decrypted_str << uncipher.final
    end
end