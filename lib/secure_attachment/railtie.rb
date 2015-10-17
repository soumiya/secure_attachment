
module SecureAttachment
  require 'rails'
  # Auto include security_attachment for active record
  class Railtie < ::Rails::Railtie
    initializer 'secure_attachment.initialize' do |_app|
      if defined?(ActiveRecord)
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::Base.send :include, SecureAttachment::Postgres
          ActiveRecord::Base.send :include, Schema
        end
      end
      # This does not work mongoid is a strange creature
      # if defined? ::Mongoid
      #   ::Mongoid::Document.send :include, SecureAttachment::Mongoid
      # end
    end
  end
end
