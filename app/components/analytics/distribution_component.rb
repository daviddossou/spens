# frozen_string_literal: true

# A total split into its parts: one stacked bar, then the biggest parts by name and the
# rest folded into one muted line. rows: [[name, amount], ...], biggest first.
class Analytics::DistributionComponent < ViewComponent::Base
  def initialize(rows:, limit: 3, more_label: nil)
    @rows = rows.to_a
    @limit = limit
    @more_label = more_label
  end

  def render?
    rows.any?
  end

  private

  attr_reader :rows, :limit

  delegate :money, :picker_icon_and_label, to: :helpers

  def total
    @total ||= rows.sum { |_, amount| amount }
  end

  def shown
    rows.first(limit)
  end

  def rest
    rows.drop(limit)
  end

  def more_label
    @more_label || t("analytics.index.accounts_more", count: rest.size)
  end

  def segment_style(amount, index)
    "width: #{total.positive? ? (amount.to_f / total * 100).round(1) : 0}%; opacity: #{[ 1 - index * 0.22, 0.2 ].max};"
  end
end
