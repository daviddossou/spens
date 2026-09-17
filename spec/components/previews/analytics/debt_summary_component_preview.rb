# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Debt summary
  class DebtSummaryComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # People on both sides, net in your favour
    def default
      render with_money(Analytics::DebtSummaryComponent.new(relations: owed + owing))
    end

    # You owe more than you are owed: negative hero
    def net_negative
      render with_money(Analytics::DebtSummaryComponent.new(relations: owed.first(1) + owing + [ relation("Landlord", "borrowed", 200_000.0) ]))
    end

    # Only money owed to you
    def only_owed_to_you
      render with_money(Analytics::DebtSummaryComponent.new(relations: owed))
    end

    # No ongoing debt: nothing renders
    def empty
      render with_money(Analytics::DebtSummaryComponent.new(relations: []))
    end

    private

    def relation(name, direction, amount)
      OpenStruct.new(name: name, initials: name.split.first(2).map { |w| w[0] }.join.upcase, net_direction: direction,
                     net_amount: amount, primary_debt: OpenStruct.new(id: "preview-#{name.parameterize}"))
    end

    def owed
      [ relation("Ama Koffi", "lent", 45_000.0), relation("Kofi Mensah", "lent", 20_000.0), relation("Yao", "lent", 5_000.0) ]
    end

    def owing
      [ relation("Georges", "borrowed", 30_000.0) ]
    end
  end
end
