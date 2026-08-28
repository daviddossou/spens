class AddOverriddenToBudgetEntries < ActiveRecord::Migration[8.0]
  def change
    # A month whose planned amount was set by hand, diverging from the recurring
    # rule — and when that exception was posted (for "Exception posée le …").
    add_column :budget_entries, :overridden, :boolean, default: false, null: false
    add_column :budget_entries, :overridden_at, :datetime
  end
end
