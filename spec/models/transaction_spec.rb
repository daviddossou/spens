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
#  account_id          :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#  user_id             :uuid             not null, indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#  index_transactions_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
