class AddLifecycleEmailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :lifecycle_emails_unsubscribed_at, :datetime
    add_column :users, :welcome_email_sent_at, :datetime
  end
end
