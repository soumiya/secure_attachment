
module SecureAttachment
  class Configuration
    attr_accessor :ciphers, :default_cipher, :log, :logger

    def initialize(params = {})
      @ciphers = params['ciphers']
      @default_cipher = params['default_cipher']
      @log = params['log'] || false
      @logger = params['logger']
    end
  end
end
