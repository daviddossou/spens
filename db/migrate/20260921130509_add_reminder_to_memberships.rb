class AddReminderToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :reminder_enabled, :boolean, default: false, null: false
    add_column :memberships, :reminder_hour, :integer, default: 20, null: false
    add_column :memberships, :reminder_last_sent_on, :date
    add_column :memberships, :reminder_declined_at, :datetime
  end
end
