class AddEssentialToBudgetItems < ActiveRecord::Migration[8.0]
  # Whether the user considers this budgeted expense something they can't do
  # without. Defaults to true: every line counts as essential until unchecked.
  def change
    add_column :budget_items, :essential, :boolean, default: true, null: false
  end
end
