# frozen_string_literal: true

module Marketing
  # @label Diagnostic
  class DiagnosticComponentPreview < ViewComponent::Preview
    ACCENTS = %w[--color-primary --color-success-dark --color-warning-dark --color-info-dark --color-violet --color-danger-dark].freeze
    GOALS = %w[save_regularly cut_wasteful_spending track_spending track_all_accounts track_repayments pay_off_debt].freeze

    # Six problems to tick, the recap below
    def default
      render Marketing::DiagnosticComponent.new(diagnostic_accents: ACCENTS, diagnostic_goals: GOALS)
    end

    # The same section in French
    def french
      render_with_template(locals: { accents: ACCENTS, goals: GOALS })
    end
  end
end
