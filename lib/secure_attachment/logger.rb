module SecureAttachment
  module Logger
    # Log a secure-attachment line. This will log to STDOUT
    # by default. Set SecureAttachment.cipher_config.log to false to turn off.
    def log(message)
      logger.info("[secure_attachment] #{message}") if logging?
    end

    def logger #:nodoc:
      @logger ||= SecureAttachment.cipher_config.logger || ::Logger.new(STDOUT)
    end

    attr_writer :logger

    def logging? #:nodoc:
      SecureAttachment.cipher_config.log
    end
  end
end
