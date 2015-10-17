module SecureAttachment
  require 'secure_attachment/mongoid/decepticon'
  module Mongoid
    def self.included(base)
      if defined? ::SecureAttachment::SecurePaperclipExtn
        base.send :extend, SecureAttachment::SecurePaperclipExtn
      end
    end
  end
end
