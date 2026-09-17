# frozen_string_literal: true

module Marketing
  # @label Feature card
  class FeatureCardComponentPreview < ViewComponent::Preview
    SHOTS = %w[feat-accounts feat-debts feat-budget feat-quick-add feat-spaces feat-goals feat-analytics feat-memory].freeze

    # The first card, collapsed
    def default
      render Marketing::FeatureCardComponent.new(card: I18n.t("landing.features.cards").first, i: 0, feature_shots: SHOTS)
    end

    # A card further down the list
    def later_card
      render Marketing::FeatureCardComponent.new(card: I18n.t("landing.features.cards")[4], i: 4, feature_shots: SHOTS)
    end

    # Every card, in the showcase column
    def all_cards
      render_with_template(locals: { cards: I18n.t("landing.features.cards"), shots: SHOTS })
    end
  end
end
