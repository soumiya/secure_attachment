require 'rails/generators/base'

module SecureAttachment
  module Generators
    class SamplekeysGenerator < Rails::Generators::Base
      desc 'Generates sample kek and edek keys and writes them to [KEK_PATH] and [EDEK_PATH]'

      argument :kek_path, type: :string, optional: :false, desc: 'absolute KEK path. ex. /etc/opt/kek_version1.dat'
      argument :edek_path, type: :string, optional: :false, desc: 'absolute EDEK path. ex. /etc/opt/edek_version1.dat'

      def create_config_file
        File.rename(kek_path, "#{kek_path}.#{Time.now.to_i}") if File.exist?(kek_path)
        File.rename(edek_path, "#{edek_path}.#{Time.now.to_i}") if File.exist?(edek_path)
        keys = SecureAttachment.generate_random_keys
        File.open(kek_path, 'wb') { |file| file.write(keys[:kek]) }
        File.open(edek_path, 'wb') { |file| file.write(keys[:edek]) }
      end
    end
  end
end
