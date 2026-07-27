class AddTimeZoneToUsersAndSpaces < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :time_zone, :string
    add_column :spaces, :time_zone, :string
  end
end
