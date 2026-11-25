# frozen_string_literal: true

# The one field of the captures screen: which account every line goes to.
class StatementImportAccountForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_name, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "StatementImport")
  end
end
