require 'spec_helper'

describe SecureAttachment::Cipher do
  let(:cipher) { SecureAttachment::Cipher }
  let(:test_text_path) { File.expand_path('./spec/files/test.txt') }
  let(:text_data) { File.open(test_text_path).read }
  context 'self' do
    describe 'decrypt_file' do
      it 'takes a simple text file and turns it into a encrypted data file' do
        pending 'WIP'
        data = cipher.encrypt(text_data)
        expect(data).to eq ''
      end
    end
  end
end
