class CreateStatementImports < ActiveRecord::Migration[8.1]
  def change
    create_table :statement_imports, id: :uuid do |t|
      t.references :space, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :account, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :status, null: false, default: "reading"
      t.string :source
      t.string :model
      t.jsonb :reads, null: false, default: []
      t.text :error
      t.datetime :saved_at
      t.datetime :undone_at

      t.timestamps
    end
    add_index :statement_imports, :status
  end
end
