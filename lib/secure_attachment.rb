require 'secure_attachment/version'

require 'openssl'
require 'digest/sha2'
require 'base64'
require 'yaml'
require 'open-uri'
require 'fernet'
require 'logger'
require 'erb'

begin; require 'pry'; rescue LoadError; end
begin; require 'mongoid'; rescue LoadError; end
begin; require 'rails'; rescue LoadError; end

require 'secure_attachment/configuration'
require 'secure_attachment/logger'
require 'secure_attachment/secure_paperclip'
if defined?(ActiveRecord)
  require 'secure_attachment/schema'
  require 'secure_attachment/postgres'
end
require 'secure_attachment/mongoid' if defined?(Mongoid)
require 'secure_attachment/railtie' if defined?(Rails)

module SecureAttachment
  extend Logger

  class << self
    attr_writer :cipher_config
  end

  def self.cipher_config
    @cipher_config ||= SecureAttachment::Configuration.new
  end

  def self.cipher_configured?
    !@cipher_config.nil? && @cipher_config.ciphers.present? && @cipher_config.default_cipher.present?
  end

  def self.configure
    yield(cipher_config) if block_given?
    cipher_config
  end

  def self.load_from_config_yml!(path, env = Rails.env)
    fail "Missing file ~ #{path.to_s.inspect}" unless File.exist? path
    yaml = YAML.load(ERB.new(File.read(path)).result)
    config = yaml[env] || yaml['default']
    fail "Missing ['default'] or a #{env} in #{path}" if config.blank?
    SecureAttachment.configure  do |c|
      c.ciphers = config['ciphers']
      c.default_cipher = config['default_cipher']
    end
  end

  def self.random_iv
    OpenSSL::Cipher.new('AES-128-CBC').random_iv
  end

  def self.dek(version = nil)
    cipher_version = version || cipher_config.default_cipher
    kek_path = cipher_config.ciphers[cipher_version]['kek_filename']
    edek_path = cipher_config.ciphers[cipher_version]['edek_filename']
    kek = File.read(kek_path).strip
    edek = File.read(edek_path).strip
    dek_verifier = Fernet.verifier(kek, edek,  enforce_ttl: false)
    dek = dek_verifier.message
  end

  def self.generate_random_keys
    kek = SecureRandom.base64(32)
    dek = SecureRandom.base64(32)
    edek = Fernet.generate(kek, dek)
    { kek: kek, dek: dek, edek: edek }
  end

  def self.cipher
    if defined?(Mongoid)
      SecureAttachment::Mongoid::Decepticon
    elsif defined?(ActiveRecord)
      SecureAttachment::Postgres::Decepticon
    else
      fail 'Your not using mongoid or active record, please pick.'
    end
  end

  def self.notify_airbrake(exception = nil, error_class: nil, error_message: '', parameters: {})
    return unless Object.const_defined?('Airbrake')
    params = {
      error_class: error_class, error_message: error_message,
      parameters: parameters
    }
    Airbrake.notify_or_ignore(exception, params)
  end
end
