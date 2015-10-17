module SecureAttachment
  class HasSecureAttachedFile
    class MissingSecureAttachementData < ::Exception; end
    attr_accessor :klass, :name, :defaults, :options
    class << self
      # This makes it easier to test this method is only called on add_decrypt_method
      #
      # this = HasSecureAttachedFile.new
      # style = String
      # default_data = String
      # cloud_storage = Boolean
      #
      def defined_method_decrypt(klass, this, style, default_data, cloud_storage)
        iv         = klass.send("#{this.name}_cipher_iv")
        version    = klass.send("#{this.name}_cipher_v")
        attachment = klass.send(this.name)
        if cloud_storage
          data = this.download_from_cloud(attachment, style, default_data)
        else
          data = this.download_from_path(attachment, style, default_data)
        end
        if this.file_exists?(attachment)
          return SecureAttachment.cipher.decrypt(data, iv, version: version)
        end
        data
      end

      def define_on(klass, name, options)
        new(klass, name, options).define
      end
    end

    def initialize(klass, name, options)
      @klass    = klass
      @name     = name
      @defaults = options.delete(:defaults)
      @options  = options
    end

    def define
      define_class_getter
      register_new_secure_attachment
      define_instance_methods
      define_query
      add_decrypt_method
      mark_protected_methods
      set_after_process_callback_methods
    end

    # This handles a check to see if any file type we are looking for is present
    #
    # This returns true or false based on the type you pass in.
    # The two types are a URI or a attachment.
    # A attachment responds to present?
    #
    def file_exists?(data)
      case data
      when String, Pathname
        return File.exist?(data)
      when Paperclip::Attachment
        return data.exists? if data.present? # This is slow but very accurate
        return false
      else
        return false
      end

    end

    # Use cloud files
    def download_from_path(attachment, style, default_data)
      path = attachment.path(style)
      return File.open(path).read if file_exists?(attachment)
      attachment_missing(path)
      default_data
    end

    # Us local path
    def download_from_cloud(attachment, style, default_data)
      path = attachment.url(style)
      return Kernel.open(path, proxy: ENV['HTTPS_PROXY']).read if file_exists?(attachment)
      attachment_missing(path)
      default_data
    end

    private

    def add_decrypt_method
      cloud_storage = Paperclip::Attachment.default_options[:storage] == 'fog'
      default_data  = load_default_url
      this          = self
      @klass.send :define_method, "decrypt_#{@name}" do |style = nil|
        HasSecureAttachedFile.defined_method_decrypt(
          self, this, style, default_data, cloud_storage
        )
      end
    end

    def attachment_missing(path = nil)
      @klass.send("#{@name}_missing") if @klass.respond_to?("#{@name}_missing")
      SecureAttachment.notify_airbrake(
        error_class: MissingSecureAttachementData,
        error_message: "Failed to download #{@name.inspect}",
        parameters: {
          path: path, attachment_name: @name, class_name: @klass.name
        }
      )
    end

    def load_default_url
      return if @defaults.nil? || @defaults[:assets_path].blank?
      assets_path = Rails.root.join(@defaults[:assets_path])
      return unless file_exists?(assets_path)
      File.open(assets_path).read
    end

    def register_new_secure_attachment
      SecureAttachment::Registry.register(@klass, @name, @options)
    end

    def define_class_getter
      @klass.extend(KlassMethods)
    end

    def define_instance_methods
      @klass.send(:include, InstanceMethods)
    end

    def mark_protected_methods
      if @klass.method_defined?(:secure_attachment_after_post_process)
        @klass.class_eval { protected :secure_attachment_after_post_process }
      end
    end

    def set_after_process_callback_methods
      if @klass.method_defined?(:secure_attachment_after_post_process) && @klass.respond_to?(:attachment_definitions)
        @klass.class_eval { after_post_process :secure_attachment_after_post_process }
      end
    end

    def define_query
      name = @name
      if @klass.method_defined?(:attachment_definitions) && @klass.attachment_definitions.keys.include?(name)
        @klass.send :define_method, "#{@name}?" do
          send(name).file? && send("#{name}_cipher_iv").present? && send("#{name}_cipher_v").present?
        end
      end
    end


    module KlassMethods
      def secure_attachment_definitions
        SecureAttachment::Registry.definitions_for(self)
      end
    end

    module InstanceMethods
      def secure_attachment_after_post_process
        attachment_names = (self.class.attachment_definitions.keys & self.class.secure_attachment_definitions.keys) || []
        attachment_names.each do |attachment_name|
          SecureAttachment.log(
            "secure_attachment_after_post_process encrpyt called for #{attachment_name}"
          )
          attachment = send(attachment_name)
          ciphers_set = false
          attachment.queued_for_write.each do |key, file|
            attr_name = attachment.name.to_s
            fail(
              "attribute '#{attr_name}_cipher_iv' is not defined"
            ) unless self.respond_to?("#{attr_name}_cipher_iv=")
            fail(
              "attribute '#{attr_name}_cipher_v' is not defined"
            ) unless self.respond_to?("#{attr_name}_cipher_v=")
            file.rewind
            # first write get ciphers, use same ciphers for rest of writes
            # for now just look specific cipher_iv and cipher_v keys,
            # later configure optional names
            if ciphers_set
              iv = send("#{attr_name}_cipher_iv")
              version = send("#{attr_name}_cipher_v")
              e_hash = SecureAttachment.cipher.encrypt(file.read, iv: iv, version: version)
              fail 'Cannot Encrypt attachment contents' if e_hash.nil?
            else
              e_hash = SecureAttachment.cipher.encrypt(file.read)
              fail 'Cannot Encrypt attachment contents' if e_hash.nil?
              send("#{attr_name}_cipher_iv=", e_hash[:iv])
              send("#{attr_name}_cipher_v=", e_hash[:version])
              ciphers_set = true
            end

            temp_file = Tempfile.new(file.original_filename)
            begin
              temp_file.binmode # BINARY MODE ACTIVATED BOOP BOP BEEP
              temp_file.write e_hash[:encrypted_data]
              temp_file.rewind

              adapted_file = Paperclip.io_adapters.for(temp_file)
              adapted_file.instance_variable_set('@original_filename', "#{key}_file.original_filename")
              adapted_file.instance_variable_set('@content_type', "#{file.content_type}-encrypted")
              attachment.queued_for_write[key] = adapted_file
            ensure
              temp_file.close
              temp_file.unlink # Deletes the temp file
            end
          end
        end
      end
    end
  end
end
