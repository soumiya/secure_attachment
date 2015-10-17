# SecureAttachment

Encrypt/Decrypts data using `AES-128-CBC` cipher algorithm.
This gem uses Fernet for encryption. It integrates with paperclip post_processing callback methods to encrypt the uploaded data.

For more info
* [Fernet](https://github.com/fernet/fernet-rb)
* [Paperclip](https://github.com/thoughtbot/paperclip)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secure_attachment'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install secure_attachment

## Configuration
generate configuration files

```ruby
rails g secure_attachment:install
```
This creates secure_attachment.yml in Rails config directory and secure_attachment.rb in config/initializers directory.
secure_attachment.yml should contain list kek and edek file paths and default cipher version to be used for each environment.

generate sample kek,edek keys

```ruby
rails g secure_attachment:samplekeys [KEK_PATH] [EDEK_PATH]
```
Ex.

```ruby
rails g secure_attachment:samplekeys  /etc/.ciphers/kek_version1.dat   /etc/.ciphers/edek_version1.dat
```
Once secure keys are generated, update `config/secure_attchment.yml`

To get {kek,dek,edek}, run

```ruby
SecureAttachment.generate_random_keys
```
in your rails console

For more info on key generation, checkout Fernet gem

### ActiveRecord Migrations

```ruby
  class AddAvatarColumnsToUsers < ActiveRecord::Migration
    def self.up
      add_secure_attachment :users, :avatar
    end

    def self.down
      remove_secure_attachment :users, :avatar
    end
  end
```

(or you can use migration generator: `rails g secure_attachment:migration user avatar`)

This creates two fields avatar_cipher_iv (cipher iv) and avatar_cipher_v (cipher version)

```ruby
  class CreateItemReferenceUrls < ActiveRecord::Migration
    def change
      create_table :item_reference_urls do |t|
        t.references :item
        t.string :reference_url
        t.attachment :reference_document #paperclip helper to create paperclip columns
        t.secure_attachment :reference_document #secure_attachment helper to create secure_attachment columns
        t.datetime :effective_from
        t.datetime :effective_to

        t.timestamps
      end
    end
  end
```

For Non ActiveRecord Applications, these fields should be explicitly created for decryption purposes

## Usage
```ruby
 require 'secure_attachment'

 encryped_resultset = SecureAttachment.cipher.encrypt(data, opts={})

 # opts can include iv, version,
 # iv defaults to random iv
 # version defaults to default version set in config
 # encryped_resultset contains {e_data, iv, version}

 # To decrypt
  plain_data = SecureAttachment.cipher.decrypt(encryped_resultset[:encrypted_data], encryped_resultset[:iv], version: encryped_resultset[:version])

```
For Rails Applications that use paperclip, to upload attachments

```ruby
class User < ActiveRecord::Base
  has_attached_file :agreements
  has_attached_file :profile_document
  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"

  has_secure_attached_files :agreements, :profile_documents
  has_secure_attached_file :avatar, defaults: {
    assets_path: 'apps/assets/images/placeholder.jpg'
  }

  #this encrypts agreements and profile_documents on upload

end
```

### Mongoid
In Mongoid you are going to have to do a bit of a change because in your model. If you see this error
```bash
`undefined method `has_secure_attached_files'
```
this is what you need to do to correct the problem. Add `include SecureAttachment::Mongoid` to the class model you are trying to secure and it should work as expected.

```ruby
class ModelWithAttachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include SecureAttachment::Mongoid
```

Second thing your are going to need to do because your not using a SQL database is to add the fields that would be added by the migrations. Include these in your Model that has the attachemnt.

```ruby
  field :attachment_cipher_iv, type: String
  field :attachment_cipher_v, type: String
```

remember to replace attachment with the name of the secure attachment file. Here is a example of how it should look when your done.

```ruby
class SolutionDiagram
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include SecureAttachment::Mongoid

  # Paperclip
  has_mongoid_attached_file :diagram
  validates_attachment :diagram,
    presence: true,
    size: { in: 0..2.megabyte, message: "must be less than 2 MB" },
    content_type: { content_type: %w(image/png image/jpg image/jpeg), message: 'must be a image(png or jpg)' }

  # Fields
  field :diagram_cipher_iv, type: String
  field :diagram_cipher_v, type: String

  # Secure Attachments
  has_secure_attached_files :diagram
end

```

## Helper

The application creates helper methods that makes it easy to download the file and decrypt the files.

Here is how we defined that method auto magically
```ruby
:define_method, "decrypt_#{@name}" do |style = nil|
```

```ruby
class SolutionDiagram
include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include SecureAttachment::Mongoid

  # Paperclip
  has_mongoid_attached_file :diagram
  validates_attachment :diagram,
    presence: true,
    styles: {
      small: '20x20'
    },
    size: { in: 0..2.megabyte, message: "must be less than 2 MB" },
    content_type: { content_type: %w(image/png image/jpg image/jpeg), message: 'must be a image(png or jpg)' }

  # Fields
  field :diagram_cipher_iv, type: String
  field :diagram_cipher_v, type: String


  has_secure_attached_files :diagram

  def decrypt
    # this method is create by Secure attachment gem
    decrypt_diagram(:small) # returns the image decrypted
  end


end
```

## Fall back data when missing file

In some cases you need to fall back to another image when one is not present.
```ruby
has_secure_attached_file :avatar, defaults: {
  assets_path: 'app/assets/images/missing_40x40.jpg' # Use file path
}
```

If you use the code above it will use file path based off your `Rails.root` to find the image and server that up in place when the image data is missing.

### Take Action on Missing data

If you want to take a action when the data is missing to help keep the database sync with the cloud files add this method to your model where you declared the `has_secure_attachment_files`.

```ruby
def avatar_missing
  avatar.destroy
  save!
end
```
Also not that a exception is created for Airbrake if you are using the airbrake gem. The exception will be formatted based off the example below. 

```ruby
error_class: MissingSecureAttachementData,
error_message: 'Failed to download encrypted image',
parameters: {
  path: path, attachment_name: @name, class_name: @klass.name
}

```
