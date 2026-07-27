# frozen_string_literal: true

module Admin
  # Review queue over the categories users invented (custom transaction_types with no
  # template). Never edits user data: mapping teaches a global alias so the NEXT user gets a
  # suggestion; promoting opens the new-taxonomy-node form; dismissing records a rejected
  # alias so the name stops resurfacing.
  class CategoryGapsController < BaseController
    def index
      @gaps = CategoryGapReport.build
    end

    # Map a gap name onto an existing taxonomy node as a global alias (active immediately).
    def map
      phrase = params[:phrase].to_s.strip
      if phrase.blank? || !TransactionTaxonomy.exists?(params[:taxonomy_key])
        return redirect_to admin_category_gaps_path, alert: t("admin.dict.invalid")
      end

      row = LearnedAlias.admin_teach(phrase: phrase, taxonomy_key: params[:taxonomy_key])
      record_admin_action("map_category_gap", target: row, metadata: { taxonomy_key: params[:taxonomy_key] })
      redirect_to admin_category_gaps_path,
                  notice: t("admin.gaps.mapped", phrase: phrase,
                            category: TransactionTaxonomy.name(params[:taxonomy_key]))
    end

    # Not a real gap: keep a rejected global row so the report filters it out for good.
    def dismiss
      phrase = params[:phrase].to_s.strip
      return redirect_to admin_category_gaps_path, alert: t("admin.dict.invalid") if phrase.blank?

      row = LearnedAlias.find_or_initialize_by(phrase: CategoryText.normalize(phrase), space_id: nil)
      row.display_phrase ||= phrase
      row.taxonomy_key = row.taxonomy_key.presence || "uncategorized_expense"
      row.source = row.source.presence || "miner"
      row.state = "rejected"
      row.save!
      record_admin_action("dismiss_category_gap", target: row)
      redirect_to admin_category_gaps_path, notice: t("admin.gaps.dismissed", phrase: phrase)
    end
  end
end
