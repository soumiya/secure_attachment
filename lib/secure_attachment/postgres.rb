module SecureAttachment
  require 'secure_attachment/postgres/decepticon'
  module Postgres
    def self.included(base)
      if defined? ::SecureAttachment::SecurePaperclipExtn
        base.send :extend, SecureAttachment::SecurePaperclipExtn
      end
    end
  end
end
