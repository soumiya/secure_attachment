require 'rails/generators/base'

module SecureAttachment
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Creates a SecureAttachment cipher keys configuration yml file at config/secure_attachment.yml'

      def self.source_root
        File.expand_path('../templates', __FILE__)
      end

      def create_config_file
        template 'secure_attachment.yml', File.join('config', 'secure_attachment.yml')
        template 'secure_attachment.rb', File.join('config', 'initializers', 'secure_attachment.rb')
      end
    end
  end
end
