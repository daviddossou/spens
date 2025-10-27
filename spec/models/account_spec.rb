# == Schema Information
#
# Table name: accounts
#
#  id          :uuid             not null, primary key
#  balance     :float            default(0.0), not null
#  name        :string           not null
#  saving_goal :float            default(0.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_accounts_on_lower_name_and_user_id  (lower((name)::text), user_id) UNIQUE
#  index_accounts_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Account, type: :model do
  subject(:account) { build(:account) }

  describe 'factories' do
    it 'is valid from factory' do
      expect(account).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    describe 'name uniqueness' do
      subject(:account) { create(:account) }

      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive }

      it 'allows same name for different users' do
        user2 = create(:user)
        account2 = build(:account, name: account.name, user: user2)
        expect(account2).to be_valid
      end

      it 'prevents duplicate names for same user (case insensitive)' do
        account2 = build(:account, name: account.name.upcase, user: account.user)
        expect(account2).not_to be_valid
        expect(account2.errors[:name]).to include('has already been taken')
      end
    end

    describe 'saving_goal validation' do
      it { is_expected.to validate_presence_of(:saving_goal) }
      it { is_expected.to validate_numericality_of(:saving_goal).is_greater_than_or_equal_to(0) }

      it 'allows zero as saving_goal' do
        account.saving_goal = 0
        expect(account).to be_valid
      end

      it 'allows positive values' do
        account.saving_goal = 1000.50
        expect(account).to be_valid
      end

      it 'rejects negative values' do
        account.saving_goal = -1
        expect(account).not_to be_valid
        expect(account.errors[:saving_goal]).to include('must be greater than or equal to 0')
      end
    end

    describe 'balance validation' do
      it { is_expected.to validate_presence_of(:balance) }
      it { is_expected.to validate_numericality_of(:balance) }

      it 'allows zero as balance' do
        account.balance = 0
        expect(account).to be_valid
      end

      it 'allows positive values' do
        account.balance = 500.75
        expect(account).to be_valid
      end

      it 'allows negative values (overdraft)' do
        account.balance = -200.0
        expect(account).to be_valid
      end

      it 'rejects non-numeric values' do
        account.balance = 'abc'
        expect(account).not_to be_valid
        expect(account.errors[:balance]).to include('is not a number')
      end
    end
  end

  describe 'database constraints' do
    it 'has a default balance of 0.0' do
      account = described_class.new(name: 'Test', user: create(:user))
      account.save!
      expect(account.balance).to eq(0.0)
    end

    it 'has a default saving_goal of 0.0' do
      account = described_class.new(name: 'Test', user: create(:user))
      account.save!
      expect(account.saving_goal).to eq(0.0)
    end
  end

  describe '.templates' do
    it 'returns a hash of template keys -> names for current locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates).to be_a(Hash)
        expect(templates.keys).to all(be_a(Symbol))
        expect(templates.values).to all(be_a(String))
      end
    end

    it 'includes expected account template keys' do
      templates = described_class.templates
      expect(templates.keys).to include(:wallet, :checking_account, :savings_account, :cash_box)
    end

    it 'returns translated values for English locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates[:wallet]).to eq('Wallet')
        expect(templates[:checking_account]).to eq('Checking account')
        expect(templates[:savings_account]).to eq('Savings account')
      end
    end

    it 'returns translated values for French locale' do
      I18n.with_locale(:fr) do
        templates = described_class.templates(:fr)
        expect(templates[:wallet]).to eq('Porte-monnaie')
      end
    end

    it 'accepts optional locale parameter' do
      templates_en = described_class.templates(:en)
      templates_fr = described_class.templates(:fr)

      expect(templates_en[:wallet]).to eq('Wallet')
      expect(templates_fr[:wallet]).to eq('Porte-monnaie')
    end

    it 'uses current I18n.locale by default' do
      I18n.with_locale(:fr) do
        templates = described_class.templates
        expect(templates[:wallet]).to eq('Porte-monnaie')
      end
    end

    it 'includes various account types' do
      templates = described_class.templates

      # Cash/physical
      expect(templates.keys).to include(:wallet, :cash_box, :envelope_1)

      # Traditional banking
      expect(templates.keys).to include(:checking_account, :savings_account)

      # Digital/cards
      expect(templates.keys).to include(:credit_card, :prepaid_card)

      # Mobile money
      expect(templates.keys).to include(:orange_money, :mtn_money, :wave_money)

      # Banks
      expect(templates.keys).to include(:ecobank, :access_bank)
    end
  end
end
