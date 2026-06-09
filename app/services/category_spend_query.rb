# frozen_string_literal: true

# Sums transaction amounts grouped by category, rolling each subcategory up to its
# parent so reports show ~17 meaningful buckets instead of dozens of leaves. With
# `drill:` set to a parent's name, it instead breaks that parent into its subcategories
# (grouping by the leaf type's name). Un-parented (custom) categories stay their own slice.
class CategorySpendQuery
  def initialize(scope, drill: nil)
    @scope = scope
    @drill = drill.presence
  end

  def call
    relation = @scope
      .joins(:transaction_type)
      .joins("LEFT JOIN transaction_types parents ON parents.id = transaction_types.parent_id")

    relation =
      if @drill
        relation.where("COALESCE(parents.name, transaction_types.name) = ?", @drill)
                .group("transaction_types.name")
      else
        relation.group(Arel.sql("COALESCE(parents.name, transaction_types.name)"))
      end

    relation.sum(:amount).transform_values(&:abs).sort_by { |_, v| -v }.to_h
  end
end
