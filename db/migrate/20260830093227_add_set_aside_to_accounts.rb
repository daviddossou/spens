class AddSetAsideToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :set_aside, :boolean, default: false, null: false
  end
end
