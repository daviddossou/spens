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
#  space_id            :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_debt_id              (debt_id)
#  index_transactions_on_space_id             (space_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
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
  end
end
