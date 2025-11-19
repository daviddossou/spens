class MakeAccountOptionalInTransactions < ActiveRecord::Migration[8.0]
  def up
    change_column_null :transactions, :account_id, true
  end

  def down
    change_column_null :transactions, :account_id, false
  end
end
