class RemoveAccountsNudgeAtFromMemberships < ActiveRecord::Migration[8.0]
  def change
    remove_column :memberships, :accounts_nudge_at, :datetime
  end
end
