# == Schema Information
#
# Table name: transactions
#
#  id                  :uuid             not null, primary key
#  amount              :float            not null
#  description         :string           not null
#  note                :text
#  transaction_date    :date             not null, indexed
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             indexed
#  debt_id             :uuid             indexed
#  fee_parent_id       :uuid             indexed
#  space_id            :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#  transfer_group_id   :uuid             indexed
#  user_id             :uuid             indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_debt_id              (debt_id)
#  index_transactions_on_fee_parent_id        (fee_parent_id)
#  index_transactions_on_space_id             (space_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#  index_transactions_on_transfer_group_id    (transfer_group_id)
#  index_transactions_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :transaction do
    transient do
      user { nil }
    end

    sequence(:description) { |n| "Transaction #{n}" }
    amount { 12.34 }
    transaction_date { Date.today }
    note { "Optional note" }
    debt { nil }

    space do
      if user
        user.spaces.first || association(:space, user: user)
      else
        association(:space)
      end
    end

    account { association(:account, space: space) }
    transaction_type { association(:transaction_type, space: space) }

    # Balance side-effects live in the services now, not model callbacks, so post
    # the ledger effect here for specs that build transactions directly.
    after(:create) do |transaction|
      TransactionLedger.apply(TransactionLedger.snapshot(transaction))
    end
  end
end
