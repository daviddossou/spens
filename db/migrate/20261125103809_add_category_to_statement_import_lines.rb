class AddCategoryToStatementImportLines < ActiveRecord::Migration[8.1]
  def change
    add_column :statement_import_lines, :transaction_type_name, :string
    add_column :statement_import_lines, :category_source, :string
    add_column :statement_import_lines, :categorization, :jsonb
  end
end
