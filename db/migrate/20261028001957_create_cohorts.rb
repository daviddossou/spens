class CreateCohorts < ActiveRecord::Migration[8.0]
  def change
    create_table :cohorts, id: :uuid do |t|
      t.string :campaign, null: false
      t.boolean :active, null: false, default: false
      t.string :whatsapp_group_url

      t.timestamps
    end
    add_index :cohorts, :campaign, unique: true
  end
end
