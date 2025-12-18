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
#  index_transaction_types_on_kind                      (kind)
#  index_transaction_types_on_lower_name_user_and_kind  (lower((name)::text), user_id, kind) UNIQUE
#  index_transaction_types_on_user_id                   (user_id)
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
  KIND_DEBT_IN = "debt_in"
  KIND_DEBT_OUT = "debt_out"

  ##
  # Associations
  belongs_to :user
  has_many :transactions, dependent: :destroy

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: [ :user_id, :kind ], case_sensitive: false }
  validates :kind, presence: true
  validates :budget_goal, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :kind, {
    income: "income",
    expense: "expense",
    debt_in: "debt_in",           # user receives money, related to a debt/loan
    debt_out: "debt_out",         # user gives money, related to a debt/loan
    transfer: "transfer",         # General type for transfers
    transfer_in: "transfer_in",   # user receives money to some account from another account
    transfer_out: "transfer_out"  # user gives money from some account to another account
  }

  ##
  # Class Methods
  class << self
    def templates(locale = I18n.locale)
      I18n.t("transaction_type_templates", locale: locale)
    end

    # Default template keys to suggest for each kind (most commonly used)
    def default_template_keys(kind)
      case kind
      when "expense"
        %w[
          groceries
          dining_out
          fuel_transport
          public_transport
          rent
          electricity_water
          telecommunication_internet
          insurance
          medical_care_pharmacy
          education_tuition
          entertainment
          clothing_shopping
          subscriptions_memberships
          maintenance_repairs
          gifts_expense
        ]
      when "income"
        %w[
          salary
          side_hustle
          business_income
          allowance
          commission_income
          investment_return
          interest_credit_bank
          grant_scholarship
          gifts_income
          financial_support_income
          refund_reimbursement
          rewards_cashback
          sports_betting_winnings
          loan_repayment
          general_income
        ]
      end
    end
  end
end
