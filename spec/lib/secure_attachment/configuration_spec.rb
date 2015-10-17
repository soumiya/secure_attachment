require 'spec_helper'

describe SecureAttachment::Configuration do
  before(:each) do
    @configuration = SecureAttachment::Configuration.new
  end

  it 'has log option' do
    expect(@configuration.respond_to?(:log)).to be_truthy
  end

  it 'has logger option' do
    expect(@configuration.respond_to?(:logger)).to be_truthy
  end

  it 'has list of ciphers' do
    expect(@configuration.respond_to?(:ciphers)).to be_truthy
  end

  it 'has default_cipher' do
    expect(@configuration.respond_to?(:default_cipher)).to be_truthy
  end

  it 'configuration options are set' do
    SecureAttachment.configure { |c| c.log = true; c.default_cipher = 'version_1' }
    expect(SecureAttachment.cipher_config.log).to be_truthy
    expect(SecureAttachment.cipher_config.default_cipher).to eq 'version_1'
  end

end
