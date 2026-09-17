# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Goals
  class GoalsComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # A goal with an ETA, one without rhythm yet, one without target
    def default
      render with_money(Analytics::GoalsComponent.new(goals: [
        progress("Laptop", current: 320_000.0, target: 800_000.0, rhythm_state: [ :eta, Date.current.beginning_of_month >> 6 ]),
        progress("Emergency fund", current: 50_000.0, target: 300_000.0, rhythm_state: [ :no_rhythm, nil ]),
        progress("Travel", current: 120_000.0, target: nil)
      ]))
    end

    # Target reached: full bar, no rhythm line
    def reached
      render with_money(Analytics::GoalsComponent.new(goals: [ progress("Moto", current: 450_000.0, target: 450_000.0) ]))
    end

    # No goal: nothing renders
    def empty
      render with_money(Analytics::GoalsComponent.new(goals: []))
    end

    private

    def progress(name, current:, target:, rhythm_state: nil)
      percentage = target ? [ (current / target * 100).round, 100 ].min : 0
      OpenStruct.new(goal: OpenStruct.new(account_id: "preview-#{name.parameterize}"), name: name,
                     account: OpenStruct.new(name: "#{name} account"), current: current, target: target,
                     target_set?: !target.nil?, percentage: percentage, rhythm_state: rhythm_state)
    end
  end
end
