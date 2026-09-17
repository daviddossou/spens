class CreateActivationMilestones < ActiveRecord::Migration[8.0]
  def change
    # One row per (user, milestone): guarantees once-only activation events.
    create_table :activation_milestones, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.datetime :created_at, null: false

      t.index [ :user_id, :name ], unique: true
    end
  end
end
