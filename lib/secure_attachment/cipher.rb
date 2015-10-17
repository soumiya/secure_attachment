module SecureAttachment
  class Cipher
    class << self
      def decrypt_file(path, iv, version = nil)
        e_data = open(path) { |f| f.read }
        decrypt(e_data, iv, version)
      end

      def decrypt(encrypted_data, iv, version: nil, dek: nil)
        dek ||= SecureAttachment.dek(version)
        fernet_verifier = Fernet.verifier(
          dek, encrypted_data, iv: iv, enforce_ttl: false
        )
        return fernet_verifier.message if fernet_verifier.valid?
        Cipher.failed_to_decrypt(fernet_verifier, version)
      end

      def encrypt(data, options = {})
        options[:iv] ||= SecureAttachment.random_iv
        options[:version] ||= SecureAttachment.cipher_config.default_cipher
        dek = SecureAttachment.dek(options[:version])
        encrypted_data = Fernet.generate(dek, data, iv: options[:iv])
        options.merge(encrypted_data: encrypted_data)
      end

      def failed_to_decrypt(fernet_verifier, version)
        version ||= SecureAttachment.cipher_config.default_cipher
        errors = fernet_verifier.token.errors
        if errors.present? && errors.errors.present?
          messages = []
          errors.errors.each do |error|
            messages << [error.property.to_s, error.message].join(' ')
          end
          messages = messages.join(', ')
          fail "Could not decrypt your file - #{messages} - (#{version})"
        end
        fail "Could not decrypt your file - (#{version})"
      end
    end
  end

  private


end
