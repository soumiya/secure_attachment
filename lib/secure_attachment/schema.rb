require 'active_support/deprecation'

module SecureAttachment
  # Provides helper methods that can be used in migrations similar to paperclip helper methods.
  module Schema
    COLUMNS = { cipher_iv: :binary, cipher_v: :string }

    def self.included(_base)
      ActiveRecord::ConnectionAdapters::Table.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Statements

      if defined?(ActiveRecord::Migration::CommandRecorder) # Rails 3.1+
        ActiveRecord::Migration::CommandRecorder.send :include, CommandRecorder
      end
    end

    module Statements
      def add_secure_attachment(table_name, *attachment_names)
        fail ArgumentError, 'Please specify attachment name in your add_secure_attachment call in your migration.' if attachment_names.empty?

        options = attachment_names.extract_options!

        attachment_names.each do |attachment_name|
          COLUMNS.each_pair do |column_name, column_type|
            column_options = options.merge(options[column_name.to_sym] || {})
            add_column(table_name, "#{attachment_name}_#{column_name}", column_type, column_options)
          end
        end
      end

      def remove_secure_attachment(table_name, *attachment_names)
        fail ArgumentError, 'Please specify attachment name in your remove_secure_attachment call in your migration.' if attachment_names.empty?
        options = attachment_names.extract_options!
        attachment_names.each do |attachment_name|
          COLUMNS.each_pair do |column_name, column_type|
            column_options = options.merge(options[column_name.to_sym] || {})
            remove_column(table_name, "#{attachment_name}_#{column_name}", column_type, column_options)
          end
        end
      end
    end

    module TableDefinition
      def secure_attachment(*attachment_names)
        options = attachment_names.extract_options!
        attachment_names.each do |attachment_name|
          COLUMNS.each_pair do |column_name, column_type|
            column_options = options.merge(options[column_name.to_sym] || {})
            column("#{attachment_name}_#{column_name}", column_type, column_options)
          end
        end
      end
    end

    module CommandRecorder
      def add_secure_attachment(*args)
        record(:add_secure_attachment, args)
      end

      private

      def invert_add_secure_attachment(args)
        [:remove_secure_attachment, args]
      end
    end
  end
end
