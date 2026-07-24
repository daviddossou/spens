# frozen_string_literal: true

module Admin
  class LearnedAliasesController < BaseController
    include Reviewable

    # Candidate/rejected keep the review queue (Reviewable). The active tier is the live
    # dictionary — rendered category-major as editable chips, not a phrase list.
    def index
      @state = params[:state].presence_in(Reviewable::STATES) || "candidate"
      return super unless @state == "active"

      @state_counts = LearnedAlias.global.group(:state).count
      rows = LearnedAlias.global.active.order(:phrase).to_a
      if params[:q].present?
        q = CategoryText.normalize(params[:q])
        rows = rows.select do |row|
          row.phrase.include?(q) ||
            CategoryText.normalize(TransactionTaxonomy.name(row.taxonomy_key).to_s).include?(q)
        end
      end
      @groups = rows.group_by(&:taxonomy_key)
      # Taxonomy display order (parent, then its children), orphaned keys last.
      @ordered_keys = TransactionTaxonomy.nodes.keys.select { |k| @groups.key?(k) } +
                      (@groups.keys - TransactionTaxonomy.nodes.keys)
      render "admin/learned_aliases/dictionary"
    end

    # Add an alias straight into the dictionary (active immediately, like a taught correction).
    def create
      phrase = params[:phrase].to_s.strip
      if phrase.blank? || !TransactionTaxonomy.exists?(params[:taxonomy_key])
        return redirect_back fallback_location: active_dictionary_path, alert: t("admin.dict.invalid")
      end

      row = LearnedAlias.admin_teach(phrase: phrase, taxonomy_key: params[:taxonomy_key])
      record_admin_action("create_alias", target: row)
      redirect_back fallback_location: active_dictionary_path, notice: t("admin.dict.added", phrase: row.phrase)
    end

    # Move a chip to another category — the "fix a wrong mapping" edit.
    def reassign
      row = LearnedAlias.find(params[:id])
      unless TransactionTaxonomy.exists?(params[:taxonomy_key])
        return redirect_back fallback_location: active_dictionary_path, alert: t("admin.dict.invalid")
      end

      row.update!(taxonomy_key: params[:taxonomy_key])
      record_admin_action("reassign_alias", target: row)
      redirect_back fallback_location: active_dictionary_path,
                    notice: t("admin.dict.moved", phrase: row.phrase, category: TransactionTaxonomy.name(row.taxonomy_key))
    end

    private

    def active_dictionary_path = admin_learned_aliases_path(state: "active")
    def reviewable_model = LearnedAlias
    def reviewable_index_path = admin_learned_aliases_path(state: params[:state])
    def approve_action = "approve_alias"
    def reject_action = "reject_alias"
    def restore_action = "restore_alias"
  end
end
