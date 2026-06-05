# frozen_string_literal: true

# Rounds declared money attributes to 2 decimal places before every save, so
# float drift (e.g. accumulating reimbursements into total_reimbursed) never
# persists sub-cent noise like 0.30000000000000004.
#
#   class Account < ApplicationRecord
#     rounds_money :balance, :saving_goal
#   end
#
# Note: bypasses ActiveRecord callbacks (increment!/decrement!, update_columns,
# update_counters) skip this. Mutate through normal assignment + save when you
# need the rounding to apply.
module RoundsMoney
  extend ActiveSupport::Concern

  included do
    class_attribute :money_attributes, instance_writer: false, default: []
  end

  class_methods do
    def rounds_money(*attributes)
      self.money_attributes += attributes.map(&:to_sym)
      before_save :round_money_attributes
    end
  end

  private

  def round_money_attributes
    money_attributes.each do |attribute|
      value = self[attribute]
      self[attribute] = value.round(2) if value.is_a?(Numeric)
    end
  end
end
