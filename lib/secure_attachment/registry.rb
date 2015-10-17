require 'singleton'

# using paperclip registry format
module SecureAttachment
  class Registry
    include Singleton

    def self.register(klass, attachment_name, attachment_options)
      instance.register(klass, attachment_name, attachment_options)
    end

    def self.clear
      instance.clear
    end

    def self.names_for(klass)
      instance.names_for(klass)
    end

    def self.definitions_for(klass)
      instance.definitions_for(klass)
    end

    def initialize
      clear
    end

    def register(klass, attachment_name, attachment_options)
      @secure_attachments ||= {}
      @secure_attachments[klass] ||= {}
      @secure_attachments[klass][attachment_name] = attachment_options
    end

    def clear
      @secure_attachments = Hash.new { |h, k| h[k] = {} }
    end

    def names_for(klass)
      @secure_attachments[klass].keys
    end

    def definitions_for(klass)
      klass.ancestors.each_with_object({}) do |ancestor, inherited_definitions|
        inherited_definitions.merge! @secure_attachments[ancestor]
      end
    end
  end
end
