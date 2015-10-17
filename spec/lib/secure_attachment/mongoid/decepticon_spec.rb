require 'spec_helper'
require 'secure_attachment/mongoid/decepticon'

describe SecureAttachment::Mongoid::Decepticon do
  let(:iv) { SecureAttachment.random_iv }
  let(:base_64_iv) { Base64.encode64(iv) }
  let(:keys) { SecureAttachment.generate_random_keys }
  before do
    allow(Base64).to receive(:encode64).and_return(base_64_iv)
  end

  context 'encrypt' do

    it 'takes random_iv by default' do
      expect(SecureAttachment).to receive(:dek).and_return(keys[:dek])
      expect(SecureAttachment).to receive(:random_iv)
      expect(Base64).to receive(:encode64).and_return(base_64_iv)
      SecureAttachment::Mongoid::Decepticon.encrypt('my data')
    end

    it 'takes cipher_config default_version for dek lookup' do
      SecureAttachment.configure { |c|  c.default_cipher = 'version_1' }
      expect(SecureAttachment).to(
        receive(:dek).with('version_1').and_return(keys[:dek])
      )
      expect(SecureAttachment).to receive(:random_iv).and_return(base_64_iv)
      SecureAttachment::Mongoid::Decepticon.encrypt('my data')
    end

    it 'accepts iv option' do
      expect(SecureAttachment).to receive(:dek).and_return(keys[:dek])
      expect(SecureAttachment).not_to receive(:random_iv)
      SecureAttachment::Mongoid::Decepticon.encrypt('my data', iv: base_64_iv)
    end

    it 'accepts version option' do
      expect(SecureAttachment).to(
        receive(:dek).with('version_2').and_return(keys[:dek])
      )
      SecureAttachment::Mongoid::Decepticon.encrypt(
        'my data', iv: base_64_iv, version: 'version_2'
      )
    end

    it 'returns a hash of encrypted_data, dek version, and iv' do
      expect(SecureAttachment).to(
        receive(:dek).with('version_2').and_return(keys[:dek])
      )
      resultset = SecureAttachment::Mongoid::Decepticon.encrypt(
        'my data', iv: base_64_iv, version: 'version_2'
      )
      expect(resultset.keys).to include(:encrypted_data, :iv, :version)
    end
  end

  context 'decrypt' do

    before do
      allow(SecureAttachment).to(
        receive(:dek).and_return(keys[:dek])
      )
    end

    let(:encrypted) do
      SecureAttachment::Mongoid::Decepticon.encrypt('my test data', iv: base_64_iv)
    end

    it 'takes cipher_config default_version for dek lookup' do
      SecureAttachment.configure { |c|  c.default_cipher = 'version_1' }
      SecureAttachment::Mongoid::Decepticon.decrypt(
        encrypted[:encrypted_data], base_64_iv
      )
    end

    it 'accepts version option' do
      SecureAttachment::Mongoid::Decepticon.decrypt(
        encrypted[:encrypted_data],
        base_64_iv,
        version: encrypted[:version]
      )
    end

    it 'returns decrypted data' do
      p_data = SecureAttachment::Mongoid::Decepticon.decrypt(
        encrypted[:encrypted_data],
        base_64_iv,
        version: encrypted[:version]
      )

      expect(p_data).to eq('my test data')
    end
  end
end
