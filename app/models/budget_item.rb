# frozen_string_literal: true

# == Schema Information
#
# Table name: budget_items
#
#  id                  :uuid             not null, primary key
#  active              :boolean          default(TRUE), not null
#  amount              :decimal(15, 2)   not null
#  ends_on             :date
#  frequency           :string           not null
#  kind                :string           not null, indexed => [space_id, debt_id]
#  starts_on           :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  debt_id             :uuid             indexed, indexed => [space_id, kind]
#  from_account_id     :uuid             indexed, indexed => [space_id, to_account_id]
#  space_id            :uuid             not null, indexed => [debt_id, kind], indexed => [from_account_id, to_account_id], indexed => [transaction_type_id], indexed
#  to_account_id       :uuid             indexed => [space_id, from_account_id], indexed
#  transaction_type_id :uuid             indexed => [space_id], indexed
#
# Indexes
#
#  index_budget_items_on_debt_id                    (debt_id)
#  index_budget_items_on_from_account_id            (from_account_id)
#  index_budget_items_on_space_and_debt_active      (space_id,debt_id,kind) UNIQUE WHERE (active AND (debt_id IS NOT NULL))
#  index_budget_items_on_space_and_transfer_active  (space_id,from_account_id,to_account_id) UNIQUE WHERE (active AND (from_account_id IS NOT NULL))
#  index_budget_items_on_space_and_type_active      (space_id,transaction_type_id) UNIQUE WHERE (active AND (transaction_type_id IS NOT NULL))
#  index_budget_items_on_space_id                   (space_id)
#  index_budget_items_on_to_account_id              (to_account_id)
#  index_budget_items_on_transaction_type_id        (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (from_account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (to_account_id => accounts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#
class BudgetItem < ApplicationRecord
  ##
  # Constants
  FREQUENCIES = %w[daily weekly biweekly monthly quarterly yearly].freeze
  # Category-based lines (income/expense), account-pair lines (transfer),
  # and person lines (debt_in: they pay me, debt_out: I pay them).
  KINDS = %w[income expense transfer debt_in debt_out].freeze
  CATEGORY_KINDS = %w[income expense].freeze
  DEBT_KINDS = %w[debt_in debt_out].freeze

  # Average occurrences per month for frequencies shorter than a month.
  # Longer frequencies materialize at full amount only in occurrence months.
  MONTHLY_FACTORS = {
    "daily" => 365.25 / 12,
    "weekly" => 52.0 / 12,
    "biweekly" => 26.0 / 12
  }.freeze

  ##
  # Associations
  belongs_to :space
  belongs_to :transaction_type, optional: true
  belongs_to :from_account, class_name: "Account", optional: true
  belongs_to :to_account, class_name: "Account", optional: true
  belongs_to :debt, optional: true
  has_many :budget_entries, dependent: :destroy

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :starts_on, presence: true

  validates :transaction_type, presence: true, if: :category_kind?
  validates :transaction_type_id, uniqueness: { scope: :space_id, conditions: -> { where(active: true) } },
                                  if: -> { active? && category_kind? }

  validates :from_account, :to_account, presence: true, if: :transfer_kind?
  validate :different_transfer_accounts, if: :transfer_kind?
  validates :from_account_id, uniqueness: { scope: [ :space_id, :to_account_id ], conditions: -> { where(active: true) } },
                              if: -> { active? && transfer_kind? }

  validates :debt, presence: true, if: :debt_kind?
  validates :debt_id, uniqueness: { scope: [ :space_id, :kind ], conditions: -> { where(active: true) } },
                      if: -> { active? && debt_kind? }

  ##
  # Scopes
  scope :active, -> { where(active: true) }

  def category_kind?
    CATEGORY_KINDS.include?(kind)
  end

  def transfer_kind?
    kind == "transfer"
  end

  def debt_kind?
    DEBT_KINDS.include?(kind)
  end

  # Whether this item produces an entry in the given month.
  def occurs_in?(month)
    month = month.beginning_of_month
    return false if month < starts_on.beginning_of_month
    return false if ends_on.present? && month > ends_on.beginning_of_month

    start = starts_on.beginning_of_month
    months_apart = (month.year - start.year) * 12 + (month.month - start.month)

    case frequency
    when "quarterly" then months_apart % 3 == 0
    when "yearly" then months_apart % 12 == 0
    else true
    end
  end

  # The monthly planned amount: normalized total for sub-monthly frequencies,
  # full amount for monthly and longer.
  def planned_amount_for(_month = nil)
    factor = MONTHLY_FACTORS[frequency]
    factor ? (amount * factor).round(2) : amount
  end

  # What this line is called on the budget page.
  def display_name
    case kind
    when "transfer" then "#{from_account&.name} → #{to_account&.name}"
    when *DEBT_KINDS then debt&.name
    else transaction_type&.name
    end
  end

  private

  def different_transfer_accounts
    return unless from_account_id.present? && from_account_id == to_account_id

    errors.add(:to_account, I18n.t("errors.messages.different_account"))
  end
end
