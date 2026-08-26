# == Schema Information
#
# Table name: debts
#
#  id               :uuid             not null, primary key
#  deadline         :date
#  direction        :string           default("lent"), not null
#  name             :string           not null
#  note             :text
#  status           :string           default("ongoing"), not null, indexed
#  total_lent       :float            default(0.0), not null
#  total_reimbursed :float            default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  space_id         :uuid             not null, indexed
#  user_id          :uuid             indexed
#
# Indexes
#
#  index_debts_on_space_id  (space_id)
#  index_debts_on_status    (status)
#  index_debts_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
class Debt < ApplicationRecord
  rounds_money :total_lent, :total_reimbursed

  ##
  # Associations
  belongs_to :space
  belongs_to :user, optional: true
  has_many :transactions, dependent: :nullify

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 }
  # Only one ONGOING debt per person+direction. Closed debts (settled/written off)
  # are history: they neither block nor get reused when the same person is
  # lent/borrowed from again.
  validates :name, uniqueness: { scope: [ :space_id, :direction ], conditions: -> { where(status: "ongoing") } }, if: :ongoing?
  validates :status, presence: true
  validates :direction, presence: true

  enum :status, {
    ongoing: "ongoing",
    paid: "paid",
    written_off: "written_off" # no longer expected: a receivable that won't come back, or a debt forgiven
  }

  enum :direction, {
    lent: "lent",        # User lent money to someone (they owe the user)
    borrowed: "borrowed"  # User borrowed money (user owes someone)
  }

  ##
  # Scopes
  scope :ongoing, -> { where(status: "ongoing") }
  scope :paid, -> { where(status: "paid") }
  scope :written_off, -> { where(status: "written_off") }
  scope :lent, -> { where(direction: "lent") }
  scope :borrowed, -> { where(direction: "borrowed") }

  ##
  # Callbacks
  # Close the debt automatically once it's fully reimbursed, wherever the totals
  # were touched (the ledger, the debt form). update_column avoids re-entrancy.
  after_save :settle_when_fully_reimbursed

  ##
  # Methods
  def remaining_balance
    (total_lent || 0.0) - (total_reimbursed || 0.0)
  end

  def mark_as_paid!
    update!(status: "paid")
  end

  private

  def settle_when_fully_reimbursed
    return unless ongoing? && total_lent.to_f.positive? && remaining_balance <= 0

    update_column(:status, "paid") # rubocop:disable Rails/SkipsModelValidations
  end
end
