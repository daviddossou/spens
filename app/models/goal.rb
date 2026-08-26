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
# A savings goal: a motivating name, an optional target amount and deadline, and
# the account that holds the money. One goal per account — the account is the
# goal's pot, so progress is measured against its balance.
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
end
