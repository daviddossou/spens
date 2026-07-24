class CreateTaxonomyNodes < ActiveRecord::Migration[8.0]
  def change
    create_table :taxonomy_nodes, id: :uuid do |t|
      t.string :key, null: false
      t.string :kind, null: false
      t.string :parent_key
      t.string :name_en, null: false
      t.string :name_fr, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :taxonomy_nodes, :key, unique: true
    add_index :taxonomy_nodes, [ :kind, :parent_key, :position ]
  end
end
