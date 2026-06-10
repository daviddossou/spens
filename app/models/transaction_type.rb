# == Schema Information
#
# Table name: transaction_types
#
#  id           :uuid             not null, primary key
#  budget_goal  :float            default(0.0)
#  kind         :string           not null, indexed
#  name         :string           not null
#  template_key :string           indexed => [space_id]
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  parent_id    :uuid             indexed
#  space_id     :uuid             not null, indexed => [template_key], indexed
#
# Indexes
#
#  index_transaction_types_on_kind                       (kind)
#  index_transaction_types_on_lower_name_space_and_kind  (lower((name)::text), space_id, kind) UNIQUE
#  index_transaction_types_on_parent_id                  (parent_id)
#  index_transaction_types_on_space_and_template_key     (space_id,template_key) UNIQUE WHERE (template_key IS NOT NULL)
#  index_transaction_types_on_space_id                   (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => transaction_types.id)
#  fk_rails_...  (space_id => spaces.id)
#
class TransactionType < ApplicationRecord
  ##
  # Constants
  KIND_TRANSFER_IN = "transfer_in"
  KIND_TRANSFER_OUT = "transfer_out"
  KIND_DEBT_IN = "debt_in"
  KIND_DEBT_OUT = "debt_out"

  # Taxonomy subcategory used to file an inline fee (e.g. a mobile-money withdrawal/send
  # fee) recorded alongside an expense, transfer, or debt_out transaction.
  FEE_KEY = "withdrawal_send_fees"

  ##
  # Associations
  belongs_to :space
  belongs_to :parent, class_name: "TransactionType", optional: true
  has_many :children, class_name: "TransactionType", foreign_key: :parent_id,
                      inverse_of: :parent, dependent: :nullify
  has_many :transactions, dependent: :destroy

  ##
  # Scopes
  scope :roots, -> { where(parent_id: nil) }

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: [ :space_id, :kind ], case_sensitive: false }
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
  # Instance Methods
  def root?
    parent_id.nil?
  end

  # Ids of this node plus its direct children — used to roll spend up to a parent category.
  def subtree_ids
    [ id, *children.ids ]
  end

  ##
  # Class Methods
  class << self
    # Built from the category taxonomy (config/transaction_taxonomy.yml) so suggestions
    # use the real Parent + Subcategory set. Shape kept compatible with callers:
    # { key.to_sym => { name:, kind: } } for every node (parents and subcategories).
    def templates(locale = I18n.locale)
      TransactionTaxonomy.nodes.each_with_object({}) do |(key, node), hash|
        hash[key.to_sym] = { name: node[locale.to_s] || node["en"], kind: node["kind"] }
      end
    end

    # The 20 subcategories suggested by default (before the user has recorded their
    # own), most-common-first. Keys must exist in the taxonomy.
    def default_template_keys(kind)
      case kind.to_s
      when "expense"
        %w[
          groceries restaurant_maquis moto_taxi public_transport fuel
          rent electricity water airtime cooking_gas
          pharmacy school_fees clothing_shoes household_items outings
          mobile_data ride_hailing street_food salon_beauty cafe_snacks
        ]
      when "income"
        %w[
          salary sales side_hustle commission_income remittance
          bonus rental_income investment_return interest allowance_perdiem
          business_income refund cashback_rewards gift_received grant_scholarship
          dividends family_support_received social_support loan_repayment_received bank_cashback
        ]
      else
        []
      end
    end
  end
end
