class CreateCategoryMemories < ActiveRecord::Migration[8.0]
  def change
    create_table :category_memories, id: :uuid do |t|
      t.references :space, type: :uuid, null: false, foreign_key: true
      t.string :taxonomy_key, null: false
      t.string :tokens, array: true, null: false, default: []
      t.integer :confirmations, null: false, default: 1
      t.timestamps
    end

    add_index :category_memories, [ :space_id, :tokens ], unique: true
  end
end
