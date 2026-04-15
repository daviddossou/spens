# == Schema Information
#
# Table name: debts
#
#  id               :uuid             not null, primary key
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
  ##
  # Associations
  belongs_to :space
  belongs_to :user, optional: true
  has_many :transactions, dependent: :nullify

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: [ :space_id, :direction ] }
  validates :status, presence: true
  validates :direction, presence: true

  enum :status, {
    ongoing: "ongoing",
    paid: "paid"
  }

  enum :direction, {
    lent: "lent",        # User lent money to someone (they owe the user)
    borrowed: "borrowed"  # User borrowed money (user owes someone)
  }

  ##
  # Scopes
  scope :ongoing, -> { where(status: "ongoing") }
  scope :paid, -> { where(status: "paid") }
  scope :lent, -> { where(direction: "lent") }
  scope :borrowed, -> { where(direction: "borrowed") }

  ##
  # Methods
  def remaining_balance
    (total_lent || 0.0) - (total_reimbursed || 0.0)
  end

  def mark_as_paid!
    update!(status: "paid")
  end
end
