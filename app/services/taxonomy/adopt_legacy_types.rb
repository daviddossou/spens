# frozen_string_literal: true

module Taxonomy
  # Gives a home to the categories the app shipped before the taxonomy existed.
  # `sync_template_names` only adopts a legacy row whose key also exists in the taxonomy; the
  # keys in config/legacy_type_map.yml have no counterpart, so their rows stayed keyless —
  # outside every parent's subtree, invisible to a parent-level budget.
  # Matches the normalized legacy name, so a row the user renamed is left alone. Then
  # re-parents every keyed row to mirror the taxonomy. Idempotent.
  class AdoptLegacyTypes
    MAP_PATH = Rails.root.join("config", "legacy_type_map.yml")
    REFERENCING_MODELS = [ Transaction, BudgetEntry, BudgetItem ].freeze

    Result = Struct.new(:adopted, :merged, :reparented, :skipped, keyword_init: true)

    def initialize(map_path: MAP_PATH)
      @map = (YAML.load_file(map_path)["map"] || {}).compact
      @result = Result.new(adopted: 0, merged: 0, reparented: 0, skipped: 0)
    end

    def call
      Space.find_each do |space|
        adopt_legacy_rows(space)
        reparent_keyed_rows(space)
      end
      @result
    end

    private

    # { [kind, normalized legacy name] => target taxonomy key }
    def legacy_index
      @legacy_index ||= {}.tap do |idx|
        %w[en fr].each do |locale|
          I18n.t("transaction_type_templates", locale: locale, default: {}).each do |key, tpl|
            target = @map[key.to_s] or next
            next if tpl[:name].blank?

            idx[[ tpl[:kind].to_s, CategoryText.normalize(tpl[:name]) ]] = target
          end
        end
      end
    end

    def adopt_legacy_rows(space)
      space.transaction_types.where(template_key: nil, kind: TransactionTaxonomy::KINDS).find_each do |type|
        target = legacy_index[[ type.kind, CategoryText.normalize(type.name) ]] or next

        owner = space.transaction_types.find_by(template_key: target)
        owner ? merge_into(type, owner) : adopt(type, target)
      end
    end

    # Repoint every reference before dropping the row — transactions are dependent: :destroy.
    def merge_into(legacy, owner)
      ActiveRecord::Base.transaction do
        REFERENCING_MODELS.each do |model|
          model.where(transaction_type_id: legacy.id).update_all(transaction_type_id: owner.id)
        end
        TransactionType.where(parent_id: legacy.id).update_all(parent_id: owner.id)
        legacy.reload.destroy!
      end
      @result.merged += 1
    rescue ActiveRecord::ActiveRecordError
      @result.skipped += 1
    end

    def adopt(type, target)
      type.update!(template_key: target, name: TransactionTaxonomy.name(target))
      @result.adopted += 1
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      # Same-named row under another key: leave the data untouched.
      @result.skipped += 1
    end

    def reparent_keyed_rows(space)
      space.transaction_types.where.not(template_key: nil).find_each do |type|
        parent_key = TransactionTaxonomy.parent_key(type.template_key)
        wanted = parent_key ? parent_row(space, parent_key) : nil
        next if type.parent_id == wanted&.id || type == wanted

        type.update!(parent: wanted)
        @result.reparented += 1
      end
    end

    def parent_row(space, key)
      @parent_rows ||= {}
      @parent_rows[[ space.id, key ]] ||=
        space.transaction_types.find_by(template_key: key) ||
        space.transaction_types.create!(template_key: key, name: TransactionTaxonomy.name(key),
                                        kind: TransactionTaxonomy.kind_of(key), budget_goal: 0.0)
    end
  end
end
