# frozen_string_literal: true

class CreateLearnedAliases < ActiveRecord::Migration[8.0]
  def change
    create_table :learned_aliases, id: :uuid do |t|
      t.string :phrase, null: false
      t.string :taxonomy_key, null: false
      t.string :state, null: false, default: "candidate"
      t.string :source, null: false
      t.integer :confirmations, null: false, default: 0

      t.timestamps
    end

    add_index :learned_aliases, :phrase, unique: true
    add_index :learned_aliases, :state
  end
end
