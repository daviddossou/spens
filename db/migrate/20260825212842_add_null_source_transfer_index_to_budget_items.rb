class AddNullSourceTransferIndexToBudgetItems < ActiveRecord::Migration[8.0]
  # Source-less transfer lines (e.g. a savings-goal contribution: "put X into
  # this account") aren't covered by the existing (from_account, to_account)
  # unique index, which requires from_account_id IS NOT NULL. Enforce one active
  # source-less line per destination instead.
  def change
    add_index :budget_items, [ :space_id, :to_account_id ],
              unique: true,
              where: "active AND from_account_id IS NULL AND to_account_id IS NOT NULL",
              name: "index_budget_items_on_space_and_dest_active_no_source"
  end
end
