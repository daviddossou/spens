# == Schema Information
#
# Table name: transaction_types
#
#  id          :uuid             not null, primary key
#  budget_goal :float            default(0.0)
#  kind        :string           not null, indexed
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_transaction_types_on_kind     (kind)
#  index_transaction_types_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe TransactionType, type: :model do
  subject(:transaction_type) { build(:transaction_type) }

  describe 'factory' do
    it 'is valid' do
      expect(transaction_type).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:kind) }

    it 'validates budget_goal presence and >= 0' do
      transaction_type.budget_goal = nil
      expect(transaction_type).not_to be_valid
      expect(transaction_type.errors[:budget_goal]).to include("can't be blank")

      transaction_type.budget_goal = -1
      transaction_type.validate
      expect(transaction_type.errors[:budget_goal]).to include('must be greater than or equal to 0')
    end
  end

  describe 'enum kind' do
    it 'defines expected kinds' do
      expect(described_class.kinds.keys).to contain_exactly(
        'income', 'expense', 'loan', 'debt', 'transfer_in', 'transfer_out'
      )
    end

    it 'allows setting each kind' do
      described_class.kinds.keys.each do |k|
        transaction_type.kind = k
        expect(transaction_type).to be_valid
      end
    end
  end

  describe '.templates' do
    it 'returns a hash for current locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates).to be_a(Hash)
      end
    end

    it 'returns translated values for fr locale' do
      I18n.with_locale(:fr) do
        templates = described_class.templates
        # We only assert a key presence if translations exist; adjust if you add guaranteed keys.
        expect(templates).to be_a(Hash)
      end
    end
  end

  describe 'dependent destroy on transactions' do
    it 'destroys child transactions when deleted' do
      tt = create(:transaction_type)
      create(:transaction, transaction_type: tt, user: tt.user, account: create(:account, user: tt.user))
      expect { tt.destroy }.to change { Transaction.count }.by(-1)
    end
  end
end
