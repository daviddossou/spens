class CreateStatementImportLines < ActiveRecord::Migration[8.1]
  def change
    create_table :statement_import_lines, id: :uuid do |t|
      t.references :statement_import, null: false, foreign_key: true, type: :uuid
      t.integer :position, null: false
      t.integer :capture_index, null: false
      t.string :status, null: false
      t.string :kind
      t.decimal :amount, precision: 15, scale: 2
      t.decimal :fee, precision: 15, scale: 2
      t.string :currency
      t.date :occurred_on
      t.datetime :occurred_at
      t.string :label
      t.string :reference
      t.decimal :balance, precision: 15, scale: 2
      t.references :account, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :counterpart_account, null: true, foreign_key: { to_table: :accounts, on_delete: :nullify }, type: :uuid
      t.references :debt, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
      t.boolean :needs_review, null: false, default: false
      t.jsonb :flags, null: false, default: []
      t.references :duplicate_of, null: true, foreign_key: { to_table: :statement_import_lines, on_delete: :nullify }, type: :uuid
      t.references :existing_transaction, null: true, foreign_key: { to_table: :transactions, on_delete: :nullify }, type: :uuid
      t.jsonb :extracted, null: false, default: {}
      t.string :decision, null: false, default: "pending"
      t.references :created_transaction, null: true, foreign_key: { to_table: :transactions, on_delete: :nullify }, type: :uuid
      t.jsonb :final

      t.timestamps
    end
  end
end
