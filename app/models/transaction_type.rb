# == Schema Information
#
# Table name: transaction_types
#
#  id          :uuid             not null, primary key
#  budget_goal :float            default(0.0)
#  kind        :string           not null, indexed
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_transaction_types_on_kind                    (kind)
#  index_transaction_types_on_lower_name_and_user_id  (lower((name)::text), user_id) UNIQUE
#  index_transaction_types_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class TransactionType < ApplicationRecord
  ##
  # Constants
  KIND_TRANSFER_IN = "transfer_in"
  KIND_TRANSFER_OUT = "transfer_out"

  ##
  # Associations
  belongs_to :user
  has_many :transactions, dependent: :destroy

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :kind, presence: true
  validates :budget_goal, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :kind, {
    income: "income",
    expense: "expense",
    loan: "loan",
    debt: "debt",
    transfer_in: "transfer_in", # System type for money coming in from another account
    transfer_out: "transfer_out" # System type for money going out to another account
  }

  ##
  # Class Methods
  class << self
    def templates(locale = I18n.locale)
      I18n.t("transaction_type_templates", locale: locale)
    end
  end
end
