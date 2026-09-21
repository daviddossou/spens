class AddSavingsProjectionToSpaces < ActiveRecord::Migration[8.0]
  def change
    add_column :spaces, :monthly_income, :decimal, precision: 15, scale: 2
    add_column :spaces, :savings_rate, :integer
  end
end
