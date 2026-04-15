# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null, indexed
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  otp_code               :string
#  otp_sent_at            :datetime
#  phone_number           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string           indexed
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
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
      # currency has moved to Space model
    end

    describe "income_frequency validation" do
      # income_frequency has moved to Space model
    end

    describe "country conditional validation" do
      # country validations have moved to Space model
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:owned_spaces).class_name("Space").dependent(:destroy) }
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:spaces).through(:memberships) }
    it { is_expected.to have_many(:accounts).through(:spaces) }
    it { is_expected.to have_many(:transaction_types).through(:spaces) }
    it { is_expected.to have_many(:transactions).through(:spaces) }
    it { is_expected.to have_many(:debts).through(:spaces) }
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
    # onboarding_current_step has moved to Space model
  end

  describe "requires_country? predicate" do
    # requires_country? has moved to Space model
  end
end
