require 'secure_attachment'

path = Rails.root.join('config', 'secure_attachment.yml')

SecureAttachment.load_from_config_yml!(path)

SecureAttachment.configure  do |c|
  c.log = Rails.env.development?
  c.logger = Rails.logger
end
