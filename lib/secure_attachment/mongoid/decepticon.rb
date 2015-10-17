module SecureAttachment
  module Mongoid
    require 'secure_attachment/cipher'
    class Decepticon < SecureAttachment::Cipher
      def self.decrypt(encrypted_data, iv, version: nil, dek: nil)
        iv = Base64.decode64(iv).encode('ascii-8bit')
        super(encrypted_data, iv, version: version, dek: dek)
      end

      def self.encrypt(data, options = {})
        options[:iv] = Base64.decode64(
          options[:iv]
        ).encode('ascii-8bit') if options[:iv].present?
        response = super(data, options)
        response[:iv] = Base64.encode64(response[:iv]).encode('utf-8')
        response
      end
    end
  end
end
