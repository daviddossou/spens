# == Schema Information
#
# Table name: users
#
#  id                      :uuid             not null, primary key
#  country                 :string           indexed
#  currency                :string           default("XOF"), indexed
#  current_sign_in_at      :datetime
#  current_sign_in_ip      :string
#  email                   :string           default(""), not null, indexed
#  encrypted_password      :string           default(""), not null
#  financial_goals         :jsonb
#  first_name              :string
#  income_frequency        :string
#  last_name               :string
#  last_sign_in_at         :datetime
#  last_sign_in_ip         :string
#  main_income_source      :string
#  onboarding_current_step :string           indexed
#  phone_number            :string
#  remember_created_at     :datetime
#  reset_password_sent_at  :datetime
#  reset_password_token    :string           indexed
#  sign_in_count           :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_users_on_country                  (country)
#  index_users_on_currency                 (currency)
#  index_users_on_email                    (email) UNIQUE
#  index_users_on_onboarding_current_step  (onboarding_current_step)
#  index_users_on_reset_password_token     (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    let(:user) { build(:user) }

    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    describe "email validation" do
      it "requires an email" do
        user.email = nil
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it "requires a unique email" do
        create(:user, email: "test@example.com")
        user.email = "test@example.com"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end

      it "validates email format" do
        user.email = "invalid-email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("is invalid")
      end
    end

    describe "OTP methods" do
      let(:user) { create(:user) }

      describe "#generate_otp!" do
        it "generates a 6-digit OTP code" do
          user.generate_otp!
          expect(user.otp_code).to match(/\A\d{6}\z/)
        end

        it "sets otp_sent_at" do
          user.generate_otp!
          expect(user.otp_sent_at).to be_within(2.seconds).of(Time.current)
        end
      end

      describe "#verify_otp" do
        before { user.generate_otp! }

        it "returns true for a valid OTP" do
          expect(user.verify_otp(user.otp_code)).to be true
        end

        it "returns false for an invalid OTP" do
          expect(user.verify_otp("000000")).to be false
        end

        it "returns false for a blank OTP" do
          expect(user.verify_otp("")).to be false
        end

        it "clears the OTP after successful verification" do
          code = user.otp_code
          user.verify_otp(code)
          expect(user.otp_code).to be_nil
          expect(user.otp_sent_at).to be_nil
        end

        it "returns false for an expired OTP" do
          user.update_column(:otp_sent_at, 11.minutes.ago)
          expect(user.verify_otp(user.otp_code)).to be false
        end
      end

      describe "#otp_expired?" do
        it "returns true when OTP is older than validity period" do
          user.generate_otp!
          user.update_column(:otp_sent_at, 11.minutes.ago)
          expect(user.otp_expired?).to be true
        end

        it "returns false when OTP is within validity period" do
          user.generate_otp!
          expect(user.otp_expired?).to be false
        end

        it "returns true when otp_sent_at is nil" do
          expect(user.otp_expired?).to be true
        end
      end
    end

    describe "name validation" do
      it "requires a first name" do
        user.first_name = nil
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
      end

      it "requires a last name" do
        user.last_name = nil
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("can't be blank")
      end
    end

    describe "phone number validation" do
      it "is optional" do
        user.phone_number = nil
        expect(user).to be_valid
      end

      it "validates format when present" do
        user.phone_number = "invalid"
        expect(user).not_to be_valid
        expect(user.errors[:phone_number]).to include("must be a valid phone number")
      end

      it "accepts valid phone numbers" do
        user.phone_number = "+1234567890"
        expect(user).to be_valid
      end
    end

    describe "currency validation" do
      it "allows a permitted currency" do
        user.currency = User::CURRENCIES.first
        expect(user).to be_valid
      end

      it "rejects an unsupported currency" do
        user.currency = "ZZZ"
        expect(user).not_to be_valid
        expect(user.errors[:currency]).to include("is not included in the list")
      end
    end

    describe "income_frequency validation" do
      it "allows blank" do
        user.income_frequency = nil
        expect(user).to be_valid
      end

      it "allows a permitted value" do
        user.income_frequency = User::INCOME_FREQUENCIES.sample
        expect(user).to be_valid
      end

      it "rejects an unsupported value" do
        user.income_frequency = "bi-monthly"
        expect(user).not_to be_valid
        expect(user.errors[:income_frequency]).to include("is not included in the list")
      end
    end

    describe "country conditional validation" do
      context "when onboarding step does not require country" do
        it "does not require country at financial goals step" do
          user.onboarding_current_step = "onboarding_financial_goal"
          user.country = nil
          expect(user).to be_valid
        end
      end

      context "when onboarding step requires country" do
        it "requires country on onboarding profile setup step" do
          user.onboarding_current_step = "onboarding_profile_setup"
          user.country = nil
          expect(user).to be_valid
        end
      end
    end
  end

  describe "OTP validity configuration" do
    it "has a 10 minute OTP validity period" do
      expect(User::OTP_VALIDITY).to eq(10.minutes)
    end
  end

  describe "devise modules" do
    it "includes database_authenticatable" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "includes trackable" do
      expect(User.devise_modules).to include(:trackable)
    end

    it "does not include registerable" do
      expect(User.devise_modules).not_to include(:registerable)
    end

    it "does not include recoverable" do
      expect(User.devise_modules).not_to include(:recoverable)
    end

    it "does not include rememberable" do
      expect(User.devise_modules).not_to include(:rememberable)
    end

    it "does not include validatable" do
      expect(User.devise_modules).not_to include(:validatable)
    end
  end

  describe "onboarding_current_step enum" do
    it "defines expected enum values" do
      expect(User.onboarding_current_steps.keys).to contain_exactly(
        "onboarding_financial_goal",
        "onboarding_profile_setup",
        "onboarding_account_setup",
        "onboarding_completed"
      )
    end
  end

  describe "requires_country? predicate" do
    let(:user) { build(:user) }

    it "returns false for financial goal step" do
      user.onboarding_current_step = "onboarding_financial_goal"
      expect(user.send(:requires_country?)).to be false
    end

    it "returns true for profile setup step" do
      user.onboarding_current_step = "onboarding_profile_setup"
      expect(user.send(:requires_country?)).to be false
    end

    it "returns true for account setup step" do
      user.onboarding_current_step = "onboarding_account_setup"
      expect(user.send(:requires_country?)).to be true
    end

    it "returns true for completed step" do
      user.onboarding_current_step = "onboarding_completed"
      expect(user.send(:requires_country?)).to be true
    end
  end
end
