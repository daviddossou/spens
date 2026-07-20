# frozen_string_literal: true

module AdminHelper
  def admin_nav_items
    [
      { label: t("admin.nav.dashboard"), path: admin_root_path },
      { label: t("admin.nav.aliases"), path: admin_learned_aliases_path },
      { label: t("admin.nav.keywords"), path: admin_learned_keywords_path },
      { label: t("admin.nav.corrections"), path: admin_corrections_path },
      { label: t("admin.nav.users"), path: admin_users_path },
      { label: t("admin.nav.spaces"), path: admin_spaces_path },
      { label: t("admin.nav.transactions"), path: admin_transactions_path },
      { label: t("admin.nav.attempts"), path: admin_quick_entry_attempts_path },
      { label: t("admin.nav.audit"), path: admin_audit_logs_path }
    ]
  end

  # Coloured pill for a learned-vocabulary state / attempt outcome / source.
  def admin_badge(text, tone: :neutral)
    tag.span(text, class: "admin-badge admin-badge--#{tone}")
  end

  STATE_TONES = { "candidate" => :warning, "active" => :success, "rejected" => :danger }.freeze
  OUTCOME_TONES = { "pending" => :neutral, "kept" => :success, "edited" => :warning, "deleted" => :danger }.freeze

  def admin_state_badge(state)
    admin_badge(t("admin.states.#{state}", default: state), tone: STATE_TONES.fetch(state.to_s, :neutral))
  end

  def admin_outcome_badge(outcome)
    admin_badge(t("admin.outcomes.#{outcome}", default: outcome), tone: OUTCOME_TONES.fetch(outcome.to_s, :neutral))
  end

  # --- learned vocabulary (works for both LearnedAlias and LearnedKeyword) ---

  def learned_type_label(row)
    row.is_a?(LearnedKeyword) ? t("admin.vocab.keyword") : t("admin.vocab.alias")
  end

  # What the row maps to, in human terms: a category name for an alias, the kind for a keyword.
  def learned_target(row)
    if row.is_a?(LearnedKeyword)
      t("admin.kinds.#{row.kind}", default: row.kind)
    else
      TransactionTaxonomy.name(row.taxonomy_key, I18n.locale)
    end
  end

  def approve_learned_path(row)
    row.is_a?(LearnedKeyword) ? approve_admin_learned_keyword_path(id: row.id) : approve_admin_learned_alias_path(id: row.id)
  end

  def reject_learned_path(row)
    row.is_a?(LearnedKeyword) ? reject_admin_learned_keyword_path(id: row.id) : reject_admin_learned_alias_path(id: row.id)
  end

  # Taxonomy nodes grouped by kind for the corrections teach form:
  # [["Expense", [["Groceries", "groceries"], ...]], ["Income", [...]]]
  def taxonomy_grouped_options
    TransactionTaxonomy.nodes.group_by { |_key, node| node["kind"] }.map do |kind, nodes|
      [ kind.capitalize, nodes.map { |key, node| [ node[I18n.locale.to_s] || node["en"], key ] }.sort ]
    end
  end

  # Human-friendly target for an audit-log row (the record may since have been deleted).
  def admin_audit_target(log)
    case (target = log.target)
    when User then link_to(target.email, admin_user_path(id: target.id))
    when LearnedAlias, LearnedKeyword then tag.code(target.phrase)
    else log.target_type.present? ? "#{log.target_type} ##{log.target_id}" : "—"
    end
  end
end
