class AddAccountsNudgeAtToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :accounts_nudge_at, :datetime
  end
end
