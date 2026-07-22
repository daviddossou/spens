class AddLocaleToSpaces < ActiveRecord::Migration[8.0]
  def change
    add_column :spaces, :locale, :string
  end
end
