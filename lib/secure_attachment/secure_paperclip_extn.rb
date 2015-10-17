module SecureAttachment
  module SecurePaperclipExtn
    def has_secure_attached_file(name, options = {})
      HasSecureAttachedFile.define_on(self, name, options)
    end

    def has_secure_attached_files(*names)
      names.each do |name|
        HasSecureAttachedFile.define_on(self, name, {})
      end
    end
  end
end
