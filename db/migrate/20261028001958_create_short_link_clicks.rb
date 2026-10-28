class CreateShortLinkClicks < ActiveRecord::Migration[8.0]
  def change
    create_table :short_link_clicks, id: :uuid do |t|
      t.string :code, null: false
      t.string :campaign
      t.text :user_agent
      t.string :referer
      t.references :user, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :short_link_clicks, :code
  end
end
