# frozen_string_literal: true

class CreateQuickEntryAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :quick_entry_attempts, id: :uuid do |t|
      t.references :space, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :transaction, type: :uuid, null: true, foreign_key: { on_delete: :nullify }

      t.text :text, null: false
      t.string :locale
      t.jsonb :rules_draft, null: false, default: {}
      t.boolean :ai_used, null: false, default: false
      t.jsonb :ai_draft
      t.string :source, null: false
      t.string :outcome, null: false, default: "pending"

      t.timestamps
    end

    add_index :quick_entry_attempts, :outcome
  end
end
