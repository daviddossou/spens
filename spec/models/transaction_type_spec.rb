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
#  space_id    :uuid             not null, indexed
#
# Indexes
#
#  index_transaction_types_on_kind                       (kind)
#  index_transaction_types_on_lower_name_space_and_kind  (lower((name)::text), space_id, kind) UNIQUE
#  index_transaction_types_on_space_id                   (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
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
    it { is_expected.to belong_to(:space) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe 'validations' do
    describe 'name validation' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }

      context 'uniqueness' do
        subject(:transaction_type) { create(:transaction_type) }

        it { is_expected.to validate_uniqueness_of(:name).scoped_to(:space_id, :kind).case_insensitive }

        it 'allows same name for different spaces' do
          space2 = create(:space)
          transaction_type2 = build(:transaction_type, name: transaction_type.name, space: space2)
          expect(transaction_type2).to be_valid
        end

        it 'prevents duplicate names for same space (case insensitive)' do
          transaction_type2 = build(:transaction_type, name: transaction_type.name.upcase, space: transaction_type.space)
          expect(transaction_type2).not_to be_valid
          expect(transaction_type2.errors[:name]).to include('has already been taken')
        end
      end

      it 'is valid with a short name' do
        transaction_type.name = 'Food'
        expect(transaction_type).to be_valid
      end

      it 'is valid with a long name' do
        transaction_type.name = 'a' * 100
        expect(transaction_type).to be_valid
      end

      it 'is invalid with name longer than 100 characters' do
        transaction_type.name = 'a' * 101
        expect(transaction_type).not_to be_valid
        expect(transaction_type.errors[:name]).to include('is too long (maximum is 100 characters)')
      end
    end

    describe 'kind validation' do
      it { is_expected.to validate_presence_of(:kind) }

      it 'is valid with income kind' do
        transaction_type.kind = 'income'
        expect(transaction_type).to be_valid
      end

      it 'is valid with expense kind' do
        transaction_type.kind = 'expense'
        expect(transaction_type).to be_valid
      end

      it 'is invalid with unknown kind' do
        expect do
          transaction_type.kind = 'invalid_kind'
        end.to raise_error(ArgumentError, /'invalid_kind' is not a valid kind/)
      end
    end

    describe 'budget_goal validation' do
      it { is_expected.to validate_presence_of(:budget_goal) }
      it { is_expected.to validate_numericality_of(:budget_goal).is_greater_than_or_equal_to(0) }

      it 'is valid with zero as budget_goal' do
        transaction_type.budget_goal = 0
        expect(transaction_type).to be_valid
      end

      it 'is valid with positive values' do
        transaction_type.budget_goal = 1000.50
        expect(transaction_type).to be_valid
      end

      it 'is invalid with negative values' do
        transaction_type.budget_goal = -1
        expect(transaction_type).not_to be_valid
        expect(transaction_type.errors[:budget_goal]).to include('must be greater than or equal to 0')
      end

      it 'is invalid with nil' do
        transaction_type.budget_goal = nil
        expect(transaction_type).not_to be_valid
        expect(transaction_type.errors[:budget_goal]).to include("can't be blank")
      end
    end
  end

  describe 'enum kind' do
    it 'defines expected kinds' do
      expect(described_class.kinds.keys).to contain_exactly(
        'income', 'expense', 'debt_in', 'debt_out', 'transfer', 'transfer_in', 'transfer_out'
      )
    end

    it 'allows setting each kind' do
      described_class.kinds.keys.each do |k|
        transaction_type.kind = k
        expect(transaction_type).to be_valid
      end
    end

    describe 'predicate methods' do
      it 'provides income? predicate' do
        transaction_type.kind = 'income'
        expect(transaction_type.income?).to be true
        expect(transaction_type.expense?).to be false
      end

      it 'provides expense? predicate' do
        transaction_type.kind = 'expense'
        expect(transaction_type.expense?).to be true
        expect(transaction_type.income?).to be false
      end

      it 'provides debt_in? predicate' do
        transaction_type.kind = 'debt_in'
        expect(transaction_type.debt_in?).to be true
        expect(transaction_type.debt_out?).to be false
      end

      it 'provides debt_out? predicate' do
        transaction_type.kind = 'debt_out'
        expect(transaction_type.debt_out?).to be true
        expect(transaction_type.debt_in?).to be false
      end

      it 'provides transfer_in? predicate' do
        transaction_type.kind = 'transfer_in'
        expect(transaction_type.transfer_in?).to be true
        expect(transaction_type.transfer_out?).to be false
      end

      it 'provides transfer_out? predicate' do
        transaction_type.kind = 'transfer_out'
        expect(transaction_type.transfer_out?).to be true
        expect(transaction_type.transfer_in?).to be false
      end

      it 'provides transfer? predicate' do
        transaction_type.kind = 'transfer'
        expect(transaction_type.transfer?).to be true
        expect(transaction_type.income?).to be false
      end
    end

    describe 'scopes' do
      let(:user) { create(:user) }
      let(:space) { user.spaces.first }
      let!(:income_type) { create(:transaction_type, :income, space: space) }
      let!(:expense_type) { create(:transaction_type, :expense, space: space) }
      let!(:debt_in_type) { create(:transaction_type, space: space, kind: 'debt_in', name: 'Debt In') }
      let!(:debt_out_type) { create(:transaction_type, space: space, kind: 'debt_out', name: 'Debt Out') }

      it 'provides income scope' do
        expect(space.transaction_types.income.count).to eq(1)
        expect(space.transaction_types.income.first).to eq(income_type)
      end

      it 'provides expense scope' do
        expect(space.transaction_types.expense.count).to eq(1)
        expect(space.transaction_types.expense.first).to eq(expense_type)
      end

      it 'provides debt_in scope' do
        expect(space.transaction_types.debt_in.count).to eq(1)
        expect(space.transaction_types.debt_in.first).to eq(debt_in_type)
      end

      it 'provides debt_out scope' do
        expect(space.transaction_types.debt_out.count).to eq(1)
        expect(space.transaction_types.debt_out.first).to eq(debt_out_type)
      end
    end
  end

  describe 'constants' do
    it 'defines KIND_TRANSFER_IN constant' do
      expect(described_class::KIND_TRANSFER_IN).to eq('transfer_in')
    end

    it 'defines KIND_TRANSFER_OUT constant' do
      expect(described_class::KIND_TRANSFER_OUT).to eq('transfer_out')
    end

    it 'defines KIND_DEBT_IN constant' do
      expect(described_class::KIND_DEBT_IN).to eq('debt_in')
    end

    it 'defines KIND_DEBT_OUT constant' do
      expect(described_class::KIND_DEBT_OUT).to eq('debt_out')
    end
  end

  describe '.templates' do
    it 'returns a hash for current locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates).to be_a(Hash)
        expect(templates.keys).to all(be_a(Symbol))
        expect(templates.values).to all(be_a(Hash))
      end
    end

    it 'includes expected transaction type categories' do
      templates = described_class.templates

      # Income types
      expect(templates.keys).to include(:salary, :side_hustle, :investment_return)

      # Expense types
      expect(templates.keys).to include(:groceries, :fuel_transport, :electricity_water)
    end

    it 'returns translated values for English locale' do
      I18n.with_locale(:en) do
        templates = described_class.templates
        expect(templates[:salary]).to eq({ kind: 'income', name: '💼 Salary' })
        expect(templates[:groceries]).to eq({ kind: 'expense', name: '🛒 Groceries' })
      end
    end

    it 'returns translated values for French locale' do
      I18n.with_locale(:fr) do
        templates = described_class.templates(:fr)
        expect(templates[:salary]).to eq({ kind: 'income', name: '💼 Salaire' })
        expect(templates[:groceries]).to eq({ kind: 'expense', name: '🛒 Provisions' })
      end
    end

    it 'accepts optional locale parameter' do
      templates_en = described_class.templates(:en)
      templates_fr = described_class.templates(:fr)

      expect(templates_en[:salary][:name]).to eq('💼 Salary')
      expect(templates_fr[:salary][:name]).to eq('💼 Salaire')
    end

    it 'uses current I18n.locale by default' do
      I18n.with_locale(:fr) do
        templates = described_class.templates
        expect(templates[:salary][:name]).to eq('💼 Salaire')
      end
    end

    it 'includes kind information in templates' do
      templates = described_class.templates

      expect(templates[:salary][:kind]).to eq('income')
      expect(templates[:groceries][:kind]).to eq('expense')
      expect(templates[:debt_repayment][:kind]).to eq('expense')
      expect(templates[:loan_repayment][:kind]).to eq('income')
      expect(templates[:transfer_in][:kind]).to eq('transfer_in')
      expect(templates[:transfer_out][:kind]).to eq('transfer_out')
    end

    it 'includes comprehensive transaction type categories' do
      templates = described_class.templates

      # Transfer types
      expect(templates.keys).to include(:transfer_in, :transfer_out)

      # Essential expenses
      expect(templates.keys).to include(:rent, :electricity_water, :groceries)

      # Income sources
      expect(templates.keys).to include(:salary, :side_hustle, :performance_bonuses)

      # Financial management
      expect(templates.keys).to include(:debt_repayment, :loan_repayment)

      # Fees
      expect(templates.keys).to include(:bank_account_fees, :mobile_money_fees)
    end
  end

  describe 'dependent destroy on transactions' do
    it 'destroys child transactions when deleted' do
      tt = create(:transaction_type)
      create(:transaction, transaction_type: tt, space: tt.space, account: create(:account, space: tt.space))
      expect { tt.destroy }.to change { Transaction.count }.by(-1)
    end

    it 'destroys multiple child transactions when deleted' do
      user = create(:user)
      space = user.spaces.first
      account = create(:account, space: space)
      tt = create(:transaction_type, space: space)

      create(:transaction, transaction_type: tt, space: space, account: account)
      create(:transaction, transaction_type: tt, space: space, account: account)
      create(:transaction, transaction_type: tt, space: space, account: account)

      expect { tt.destroy }.to change { Transaction.count }.by(-3)
    end

    it 'does not affect transactions of other transaction types' do
      user = create(:user)
      space = user.spaces.first
      account = create(:account, space: space)
      tt1 = create(:transaction_type, space: space)
      tt2 = create(:transaction_type, space: space, name: 'Other Type')

      create(:transaction, transaction_type: tt1, space: space, account: account)
      create(:transaction, transaction_type: tt2, space: space, account: account)

      expect { tt1.destroy }.to change { Transaction.count }.by(-1)
      expect(tt2.transactions.count).to eq(1)
    end
  end

  describe 'database defaults' do
    it 'has a default budget_goal of 0.0' do
      transaction_type = described_class.new(name: 'Test', kind: 'expense', space: create(:space))
      transaction_type.save!
      expect(transaction_type.budget_goal).to eq(0.0)
    end
  end

  describe 'database indexes' do
    it 'has an index on space_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:transaction_types, :space_id)).to be true
    end

    it 'has an index on kind' do
      expect(ActiveRecord::Base.connection.index_exists?(:transaction_types, :kind)).to be true
    end

    it 'has a unique compound index on lower(name), space_id and kind' do
      indexes = ActiveRecord::Base.connection.indexes(:transaction_types)
      compound_index = indexes.find { |i| i.name == 'index_transaction_types_on_lower_name_space_and_kind' }

      expect(compound_index).to be_present
      expect(compound_index.unique).to be true
    end
  end

  describe 'integration scenarios' do
    let(:user) { create(:user) }
    let(:space) { user.spaces.first }

    it 'creates a complete transaction type with all attributes' do
      transaction_type = create(:transaction_type,
        space: space,
        name: 'Monthly Rent',
        kind: 'expense',
        budget_goal: 1500.0
      )

      expect(transaction_type).to be_persisted
      expect(transaction_type.name).to eq('Monthly Rent')
      expect(transaction_type.kind).to eq('expense')
      expect(transaction_type.budget_goal).to eq(1500.0)
      expect(transaction_type.expense?).to be true
    end

    it 'supports different kinds for the same space' do
      income_type = create(:transaction_type, :income, space: space, name: 'Salary')
      expense_type = create(:transaction_type, :expense, space: space, name: 'Groceries')
      debt_out_type = create(:transaction_type, space: space, name: 'Debt Payment', kind: 'debt_out')

      expect(space.transaction_types.count).to eq(3)
      expect(space.transaction_types.income.count).to eq(1)
      expect(space.transaction_types.expense.count).to eq(1)
      expect(space.transaction_types.debt_out.count).to eq(1)
    end

    it 'handles budget tracking for expense types' do
      groceries = create(:transaction_type, :expense, space: space, name: 'Groceries', budget_goal: 500.0)
      transport = create(:transaction_type, :expense, space: space, name: 'Transport', budget_goal: 200.0)

      expect(groceries.budget_goal).to eq(500.0)
      expect(transport.budget_goal).to eq(200.0)
    end

    it 'supports transfer types for internal account transfers' do
      transfer_in = create(:transaction_type, space: space, name: 'Transfer In', kind: 'transfer_in')
      transfer_out = create(:transaction_type, space: space, name: 'Transfer Out', kind: 'transfer_out')

      expect(transfer_in.kind).to eq(described_class::KIND_TRANSFER_IN)
      expect(transfer_out.kind).to eq(described_class::KIND_TRANSFER_OUT)
      expect(transfer_in.transfer_in?).to be true
      expect(transfer_out.transfer_out?).to be true
    end
  end
end
