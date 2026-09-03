# frozen_string_literal: true

# == Schema Information
#
# Table name: goals
#
#  id            :uuid             not null, primary key
#  deadline      :date
#  name          :string           not null
#  target_amount :decimal(15, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null, indexed
#  space_id      :uuid             not null, indexed
#
# Indexes
#
#  index_goals_on_account_id  (account_id) UNIQUE
#  index_goals_on_space_id    (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#
class Goal < ApplicationRecord
  rounds_money :target_amount

  ##
  # Associations
  belongs_to :space
  belongs_to :account

  ##
  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :account_id, uniqueness: true
  validates :target_amount, numericality: { greater_than: 0 }, allow_nil: true

  ##
  # Callbacks
  # Meta activation milestone: end of guide chapter 4 (CAPI-only, once per user).
  after_create_commit -> { Meta::Activation.record(space&.user, :spens_first_goal) }
  # A goal is the app's definition of money set aside, so its account carries the
  # flag — one flag then drives the dashboard's "mis de côté", the budget's
  # committed line and the picker order. Dropping the goal leaves it: the account
  # is still a savings account, it just has no target any more.
  after_save :mark_account_set_aside
  after_destroy :retire_plan_line

  ##
  # Instance Methods
  def target_set?
    target_amount.to_f.positive?
  end

  def current_amount
    account&.balance.to_f
  end

  def remaining
    return nil unless target_set?

    [ target_amount - current_amount, 0 ].max
  end

  private

  def mark_account_set_aside
    account.update_column(:set_aside, true) unless account.set_aside?
  end

  # The goal owns the source-less line that plans its monthly contribution.
  # Without this, deleting the goal leaves the plan committing money every month
  # to a target that no longer exists.
  def retire_plan_line
    line = space.budget_items.active
                .find_by(kind: "transfer", to_account_id: account_id, from_account_id: nil)
    return if line.nil?

    line.update!(active: false)
    Budgets::RematerializeItem.call(line)
  end
end
