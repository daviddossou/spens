# == Schema Information
#
# Table name: transactions
#
#  id                  :uuid             not null, primary key
#  amount              :float            not null
#  description         :string           not null
#  label               :string
#  note                :text
#  transaction_date    :date             not null, indexed
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             indexed
#  debt_id             :uuid             indexed
#  fee_parent_id       :uuid             indexed
#  space_id            :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#  transfer_group_id   :uuid             indexed
#  user_id             :uuid             indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_debt_id              (debt_id)
#  index_transactions_on_fee_parent_id        (fee_parent_id)
#  index_transactions_on_space_id             (space_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#  index_transactions_on_transfer_group_id    (transfer_group_id)
#  index_transactions_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#  fk_rails_...  (user_id => users.id)
#
class Transaction < ApplicationRecord
  rounds_money :amount

  ##
  # Associations
  belongs_to :space
  belongs_to :user, optional: true
  belongs_to :transaction_type
  belongs_to :account, optional: true
  belongs_to :debt, optional: true

  # A provider fee recorded as its own expense, linked to the transaction it
  # belongs to so it can be edited/removed alongside its parent.
  belongs_to :fee_parent, class_name: "Transaction", optional: true
  has_one :fee, class_name: "Transaction", foreign_key: :fee_parent_id, inverse_of: :fee_parent, dependent: :nullify

  ##
  # Nested Attributes
  accepts_nested_attributes_for :account
  accepts_nested_attributes_for :transaction_type

  ##
  # Validations
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_date, presence: true

  ##
  # Scopes
  scope :transfer_group, ->(group_id) { where(transfer_group_id: group_id) }

  # Free-text search across description, note, category name, account name and
  # amount (any number in the query matches the absolute amount, so "5 euros"
  # finds 5.00 transactions).
  scope :search, ->(query) do
    term = query.to_s.strip
    next all if term.blank?

    clauses = [
      "transactions.description ILIKE :pattern",
      "transactions.note ILIKE :pattern",
      "transactions.label ILIKE :pattern",
      "transaction_types.name ILIKE :pattern",
      "accounts.name ILIKE :pattern"
    ]
    binds = { pattern: "%#{sanitize_sql_like(term)}%" }

    if (number = term.tr(",", ".")[/\d+(\.\d+)?/])
      clauses << "ROUND(ABS(transactions.amount)::numeric, 2) = :number"
      binds[:number] = number.to_f.round(2)
    end

    left_joins(:transaction_type, :account).where(clauses.join(" OR "), **binds)
  end

  # The other leg of a transfer (same transfer_group_id, different row). Nil for
  # non-transfers, legacy unpaired legs, or if the partner was already removed.
  def transfer_partner
    return nil if transfer_group_id.blank?

    space.transactions.where(transfer_group_id: transfer_group_id).where.not(id: id).first
  end

  # This transfer's two legs keyed by direction (either may be nil).
  def transfer_legs
    legs = [ self, transfer_partner ].compact
    {
      out: legs.find { |t| t.transaction_type.kind == "transfer_out" },
      in: legs.find { |t| t.transaction_type.kind == "transfer_in" }
    }
  end
end
