# frozen_string_literal: true

class Debts::TotalsComponent < ViewComponent::Base
  def initialize(i_owe:, owed_to_me:, total_i_owe:, total_owed_to_me:)
    @i_owe = i_owe
    @owed_to_me = owed_to_me
    @total_i_owe = total_i_owe
    @total_owed_to_me = total_owed_to_me
  end

  private

  attr_reader :i_owe, :owed_to_me, :total_i_owe, :total_owed_to_me

  delegate :money, to: :helpers
end
