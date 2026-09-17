# frozen_string_literal: true

module Debts
  # @label Totals
  class TotalsComponentPreview < ViewComponent::Preview
    # People on both sides, compact totals
    def default
      render_totals(owed_to_me: [ :myri, :ali ], i_owe: [ :georges ], total_owed_to_me: 1_250_000, total_i_owe: 35_000)
    end

    # Nothing owed to you
    def one_sided
      render_totals(owed_to_me: [], i_owe: [ :georges ], total_owed_to_me: 0, total_i_owe: 35_000)
    end

    private

    def render_totals(**args)
      render_with_template(template: "shared/space_context", locals: { component: Debts::TotalsComponent.new(**args) })
    end
  end
end
