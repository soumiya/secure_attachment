require 'spec_helper'

describe SecureAttachment::Registry do
  before do
    SecureAttachment::Registry.clear
  end

  context '.names_for' do
    it 'includes secure attachment names for the given class' do
      foo = Class.new
      SecureAttachment::Registry.register(foo, :avatar, {})

      expect(SecureAttachment::Registry.names_for(foo)).to eq [:avatar]
    end

    it 'produces the empty array for a missing key' do
      expect(SecureAttachment::Registry.names_for(Class.new)).to be_empty
    end
  end

  context '.definitions_for' do
    it 'produces the secure attachment name and options' do
      expected_definitions = {
        avatar: {},
        greeter: {}
      }
      foo = Class.new
      SecureAttachment::Registry.register(foo, :avatar, {})
      SecureAttachment::Registry.register(foo, :greeter, {})

      definitions = SecureAttachment::Registry.definitions_for(foo)

      expect(definitions).to eq expected_definitions
    end

    it 'produces defintions for subclasses' do
      expected_definitions = { avatar: { yo: 'greeting' } }
      Foo = Class.new
      Bar = Class.new(Foo)
      SecureAttachment::Registry.register(Foo, :avatar, expected_definitions[:avatar])

      definitions = SecureAttachment::Registry.definitions_for(Bar)

      expect(definitions).to eq expected_definitions
    end
  end

  context '.clear' do
    it 'removes all of the existing secure attachment definitions' do
      foo = Class.new
      SecureAttachment::Registry.register(foo, :greeter, {})
      SecureAttachment::Registry.clear
      expect(SecureAttachment::Registry.names_for(foo)).to be_empty
    end
  end

end
