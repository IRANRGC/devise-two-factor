require 'spec_helper'
require 'active_model'

class TwoFactorAuthenticatableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'*4

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

class TwoFactorAuthenticatableWithCustomizeAttrEncryptedDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks

  # like https://github.com/tinfoil/devise-two-factor/blob/cf73e52043fbe45b74d68d02bc859522ad22fe73/UPGRADING.md#guide-to-upgrading-from-2x-to-3x
  extend ::AttrEncrypted
  attr_encrypted :otp_secret,
                  :key       => 'test-key'*8,
                  :mode      => :per_attribute_iv_and_salt,
                  :algorithm => 'aes-256-cbc'

  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'*4

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableWithCustomizeAttrEncryptedDouble.new }

    it_behaves_like 'two_factor_authenticatable'

    before :each do
      subject.otp_secret = subject.class.generate_otp_secret
      subject.consumed_timestep = nil
    end

    describe 'otp_secret options' do
      it 'should be of the key' do
        if attr_encrypted_is_rails_seven_compatible?
          expect(subject.attr_encrypted_encrypted_attributes[:otp_secret][:key]).to eq('test-key'*8)
        else
          expect(subject.encrypted_attributes[:otp_secret][:key]).to eq('test-key'*8)
        end
      end

      it 'should be of the mode' do
        if attr_encrypted_is_rails_seven_compatible?
          expect(subject.attr_encrypted_encrypted_attributes[:otp_secret][:mode]).to eq(:per_attribute_iv_and_salt)
        else
          expect(subject.encrypted_attributes[:otp_secret][:mode]).to eq(:per_attribute_iv_and_salt)
        end
      end

      it 'should be of the mode' do
        if attr_encrypted_is_rails_seven_compatible?
          expect(subject.attr_encrypted_encrypted_attributes[:otp_secret][:algorithm]).to eq('aes-256-cbc')
        else
          expect(subject.encrypted_attributes[:otp_secret][:algorithm]).to eq('aes-256-cbc')
        end
      end

      def attr_encrypted_is_rails_seven_compatible?
        Gem::Version.new(AttrEncrypted::Version.string) >= Gem::Version.new('4.0.0')
      end
    end
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When clean_up_passwords is called ' do
    subject { TwoFactorAuthenticatableDouble.new }
    before :each do
      subject.otp_attempt = 'foo'
      subject.password_confirmation = 'foo'
    end
    it 'otp_attempt should be nill' do 
      subject.clean_up_passwords
      expect(subject.otp_attempt).to be_nil
    end
    it 'password_confirmation should be nill' do 
      subject.clean_up_passwords
      expect(subject.password_confirmation).to be_nil
    end
  end
end


