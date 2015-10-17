require 'rails/generators/base'
require 'rails/generators/active_record'

module SecureAttachment
  module Generators
    class MigrationGenerator < ActiveRecord::Generators::Base
      desc 'Create a migration to add secure_attachment specific fields to your model. ' \
           'The NAME argument is the name of your model, and the following ' \
           'arguments are the name of the fields to be secured'

      argument :attachment_names, required: true, type: :array,
                                  desc: 'The names of the fields(s) to add.'

      def self.source_root
        File.expand_path('../templates', __FILE__)
      end

      def generate_migration
        migration_template 'secure_attachment_migration.rb.erb', "db/migrate/#{migration_file_name}"
      end

      def migration_name
        "add_secure_attachment_#{attachment_names.join('_')}_to_#{name.underscore.pluralize}"
      end

      def migration_file_name
        "#{migration_name}.rb"
      end

      def migration_class_name
        migration_name.camelize
      end
    end
  end
end
