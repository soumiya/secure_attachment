# require 'secure_attachment' Not needed required in spec helper
ciphers = {
  version_1: {
    kek_filename: File.expand_path('./spec/ciphers/kek_version_1.dat'),
    edek_filename: File.expand_path('./spec/ciphers/edek_version_1.dat')
  }
}

SecureAttachment.configure  do |c|
  c.log = false
  c.default_cipher = 'version_1'
  c.ciphers = ciphers
end
