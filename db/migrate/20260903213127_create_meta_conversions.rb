class CreateMetaConversions < ActiveRecord::Migration[7.1]
  def change
    # One row per (user, event): guarantees once-only Meta CAPI activation events.
    create_table :meta_conversions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :event_name, null: false
      t.uuid :event_id, null: false
      t.datetime :created_at, null: false

      t.index [ :user_id, :event_name ], unique: true
    end
  end
end
