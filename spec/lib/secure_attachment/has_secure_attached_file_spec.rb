require 'spec_helper'

describe SecureAttachment::HasSecureAttachedFile do
  let(:has_secure_attachment_file) { SecureAttachment::HasSecureAttachedFile }
  let(:foo_class) { Class.new }
  let(:new_secure_attachment) do
    has_secure_attachment_file.new(foo_class, 'avatar', {})
  end
  let(:defined) { new_secure_attachment.define }
  let(:attachment) { double(path: 'something') }
  let(:present_text_file_path) { File.expand_path('./spec/files/test.txt') }
  let(:paperclip_attachment) { Paperclip::Attachment.new('avatar', Class) }

  describe 'defined_method_decrypt' do
    let(:klass) do
      double(avatar_cipher_iv: 'iv', avatar_cipher_v: 'v', avatar: 'maybe')
    end
    let(:data) { 'blah blah blah I am data' }
    it 'should build correctly when called' do
      expect(new_secure_attachment).to receive(:download_from_cloud).with(
        klass.avatar, 'thumb', nil
      ).and_return(data)
      expect(new_secure_attachment).to receive(:file_exists?).with(
        klass.avatar
      ).and_return(true)
      expect(SecureAttachment.cipher).to receive(:decrypt).with(
        data, klass.avatar_cipher_iv, version: klass.avatar_cipher_v
      ).and_return(data)
      results = has_secure_attachment_file.defined_method_decrypt(
        klass, new_secure_attachment, 'thumb', nil, true
      )
      expect(results).to eq data
    end
  end
  describe 'define' do
    it 'add secure_attachment_definitions as class method' do
      defined
      expect(foo_class.methods.include?(:secure_attachment_definitions)).to be_truthy
    end

    it 'registers in SecureAttachment::Registry' do
      defined
      expect(SecureAttachment::Registry.names_for(foo_class)).to eq ['avatar']
    end

    it 'sets instance_method secure_attachment_after_post_process' do
      defined
      expect(foo_class.new.protected_methods.include?(:secure_attachment_after_post_process)).to be_truthy
    end

    it 'sets after_post_process callback ' do
      expect(foo_class).to receive(:validates_each).and_return(true)
      expect(foo_class).to receive(:after_save).and_return(true)
      expect(foo_class).to receive(:before_destroy).and_return(true)
      expect(foo_class).to receive(:after_commit).and_return(true)
      expect(foo_class).to receive(:define_paperclip_callbacks).and_return(true)
      expect(foo_class).to receive(:validates_media_type_spoof_detection).and_return(false)
      expect(foo_class).to receive(:after_post_process)

      Paperclip::HasAttachedFile.define_on(foo_class, 'avatar', {})
      defined
    end
  end

  describe 'file_exists?' do
    it 'returns true for file path' do
      results = new_secure_attachment.file_exists?(present_text_file_path)
      expect(results).to be_truthy
    end

    it 'returns true for Paperclip::Attachment' do
      expect(paperclip_attachment).to receive(:present?).and_return(true)
      expect(paperclip_attachment).to receive(:exists?).and_return(true)
      results = new_secure_attachment.file_exists?(paperclip_attachment)
      expect(results).to be_truthy
    end
  end

  describe 'add_decrypt_method' do
    let(:decrypt_methods) do
      new_secure_attachment.send(:add_decrypt_method)
    end
    it 'adds a new method called avatar' do
      expect(decrypt_methods).to be_truthy
    end
  end

  describe 'download_from_path' do
    let(:file) { double(read: 'something') }
    it 'class send name on klass' do
      expect(attachment).to receive(:path).with(:default)
      expect(new_secure_attachment).to receive(:file_exists?).and_return(true)
      expect(File).to receive(:open).and_return(file)
      results = new_secure_attachment.download_from_path(attachment, :default, nil)
      expect(results).to eq file.read
    end
  end

  describe 'download_from_cloud' do
    let(:file) { double(read: 'something') }
    it 'class send name on klass' do
      expect(attachment).to receive(:url).with(:default).and_return(attachment.path)
      expect(new_secure_attachment).to receive(:file_exists?).and_return(true)
      expect(Kernel).to(
        receive(:open).with(attachment.path, proxy: nil).and_return(file)
      )
      expect(file).to receive(:read).and_return(file.read)
      results = new_secure_attachment.download_from_cloud(attachment, :default, nil)
      expect(results).to eq file.read
    end
  end

  describe 'attachment_missing' do
    it 'has some expections' do
      expect(foo_class).to(
        receive(:respond_to?).with('avatar_missing').and_return(true)
      )
      expect(foo_class).to receive(:send).with('avatar_missing')
      expect(SecureAttachment).to receive(:notify_airbrake).with(
        error_class: SecureAttachment::HasSecureAttachedFile::MissingSecureAttachementData,
        error_message: "Failed to download \"avatar\"",
        parameters: {
          path: 'path', attachment_name: 'avatar', class_name: nil
        }
      )
      new_secure_attachment.send(:attachment_missing, 'path')
    end
  end

end
