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
#  index_accounts_on_user_id  (user_id)
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

    it 'validates name length max 100' do
      account.name = 'a' * 101
      expect(account).not_to be_valid
      expect(account.errors[:name]).to include('is too long (maximum is 100 characters)')
    end

    it 'requires saving_goal present and >= 0' do
      account.saving_goal = nil
      expect(account).not_to be_valid
      expect(account.errors[:saving_goal]).to include("can't be blank")

      account.saving_goal = -1
      account.validate
      expect(account.errors[:saving_goal]).to include('must be greater than or equal to 0')
    end

    it 'requires balance present and numeric' do
      account.balance = nil
      expect(account).not_to be_valid
      expect(account.errors[:balance]).to include("can't be blank")

      account.balance = 'abc'
      account.validate
      expect(account.errors[:balance]).to include('is not a number')

      account.balance = -200.0
      expect(account).to be_valid
    end
  end

  describe '.templates' do
    it 'returns a hash of template keys -> names for current locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates).to be_a(Hash)
        expect(templates.keys).to include(:wallet, :checking_account)
      end
    end

    it 'returns translated values for another locale (fr)' do
      I18n.with_locale(:fr) do
        templates = described_class.templates
        expect(templates[:wallet]).to eq('Porte-monnaie')
      end
    end
  end
end

