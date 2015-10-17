require 'spec_helper'
require 'secure_attachment/schema'

describe SecureAttachment::Schema do

  context 'within table definition' do
    before do
      reset_class 'Dummy'
    end

    after do
      Dummy.connection.drop_table :dummies rescue nil
    end

    describe 'using #secure_attachment' do
      it 'creates secure attachment columns' do
        Dummy.connection.create_table :dummies, force: true do |t|
          t.secure_attachment :avatar
        end

        columns = Dummy.columns.map { |column| [column.name, column.type] }

        expect(columns).to include(['avatar_cipher_iv', :binary])
        expect(columns).to include(['avatar_cipher_v', :string])
      end
    end

    describe 'using #secure_attachment with multiple attachments' do
      it 'creates secure attachment columns' do
        Dummy.connection.create_table :dummies, force: true do |t|
          t.secure_attachment :avatar, :profile_doc
        end
        columns = Dummy.columns.map { |column| [column.name, column.type] }

        expect(columns).to include(['avatar_cipher_iv', :binary])
        expect(columns).to include(['avatar_cipher_v', :string])
        expect(columns).to include(['profile_doc_cipher_iv', :binary])
        expect(columns).to include(['profile_doc_cipher_v', :string])
      end
    end

  end

  context 'within schema statement' do
    before do
      reset_class 'Dummy'
      Dummy.connection.create_table :dummies, force: true
    end

    after do
      Dummy.connection.drop_table :dummies rescue nil
    end

    describe 'migrating up' do
      context 'with single attachment' do
        it 'creates secure attachment columns' do
          Dummy.connection.add_secure_attachment :dummies, :avatar
          columns = Dummy.columns.map { |column| [column.name, column.type] }

          expect(columns).to include(['avatar_cipher_iv', :binary])
          expect(columns).to include(['avatar_cipher_v', :string])
        end
      end

      context 'with multiple attachment' do
        it 'creates secure attachment columns' do
          Dummy.connection.add_secure_attachment :dummies, :avatar, :profile

          columns = Dummy.columns.map { |column| [column.name, column.type] }

          expect(columns).to include(['avatar_cipher_iv', :binary])
          expect(columns).to include(['avatar_cipher_v', :string])
          expect(columns).to include(['profile_cipher_iv', :binary])
          expect(columns).to include(['profile_cipher_v', :string])
        end
      end

    end

    describe 'migrating down' do
      before do
        Dummy.connection.change_table :dummies do |t|
          t.column :avatar_cipher_iv, :binary
          t.column :avatar_cipher_v, :string
        end
      end
      it 'drops the secure attachment columns' do
        Dummy.connection.remove_secure_attachment :dummies, :avatar
        columns = Dummy.columns.map { |column| [column.name, column.type] }

        expect(columns).not_to include(['avatar_cipher_iv', :binary])
        expect(columns).not_to include(['avatar_cipher_v', :string])

      end
    end
  end

  private

  def reset_class(class_name)
    ActiveRecord::Base.send(:include, SecureAttachment::Schema)
    Object.send(:remove_const, class_name) rescue nil
    klass = Object.const_set(class_name, Class.new(ActiveRecord::Base))
    klass.reset_column_information
    klass.connection_pool.clear_table_cache!(klass.table_name) if klass.connection_pool.respond_to?(:clear_table_cache!)
    klass.connection.schema_cache.clear_table_cache!(klass.table_name) if klass.connection.respond_to?(:schema_cache)
    klass
  end

end
