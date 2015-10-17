require 'spec_helper'
require 'secure_attachment/postgres/decepticon'

describe SecureAttachment::Postgres::Decepticon do
let!(:iv) { SecureAttachment.random_iv }
let(:base_64_iv) { Base64.encode64(iv) }
let(:keys) { SecureAttachment.generate_random_keys }

context 'encrypt' do

  it 'takes random_iv by default' do
    expect(SecureAttachment).to receive(:dek).and_return(keys[:dek])
    expect(SecureAttachment).to receive(:random_iv)
    SecureAttachment::Postgres::Decepticon.encrypt('my data')
  end

  it 'takes cipher_config default_version for dek lookup' do
    SecureAttachment.configure { |c|  c.default_cipher = 'version_1' }
    expect(SecureAttachment).to(
      receive(:dek).with('version_1').and_return(keys[:dek])
    )
    expect(SecureAttachment).to receive(:random_iv).and_return(iv)
    SecureAttachment::Postgres::Decepticon.encrypt('my data')
  end

  it 'accepts iv option' do
    expect(SecureAttachment).to receive(:dek).and_return(keys[:dek])
    expect(SecureAttachment).not_to receive(:random_iv)
    SecureAttachment::Postgres::Decepticon.encrypt('my data', iv: iv)
  end

  it 'accepts version option' do
    expect(SecureAttachment).to(
      receive(:dek).with('version_2').and_return(keys[:dek])
    )
    SecureAttachment::Postgres::Decepticon.encrypt(
      'my data', iv: iv, version: 'version_2'
    )
  end

  it 'returns a hash of encrypted_data, dek version, and iv' do
    expect(SecureAttachment).to(
      receive(:dek).with('version_2').and_return(keys[:dek])
    )
    resultset = SecureAttachment::Postgres::Decepticon.encrypt(
      'my data', iv: iv, version: 'version_2'
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
    SecureAttachment::Postgres::Decepticon.encrypt('my test data', iv: iv)
  end

  it 'takes cipher_config default_version for dek lookup' do
    SecureAttachment.configure { |c|  c.default_cipher = 'version_1' }
    SecureAttachment::Postgres::Decepticon.decrypt(
      encrypted[:encrypted_data], iv
    )
  end

  it 'accepts version option' do
    SecureAttachment::Postgres::Decepticon.decrypt(
      encrypted[:encrypted_data],
      iv,
      version: encrypted[:version]
    )
  end

  it 'returns decrypted data' do
    p_data = SecureAttachment::Postgres::Decepticon.decrypt(
      encrypted[:encrypted_data],
      iv,
      version: encrypted[:version]
    )

    expect(p_data).to eq('my test data')
  end
end

end
