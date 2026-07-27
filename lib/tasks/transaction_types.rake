# frozen_string_literal: true

namespace :transaction_types do
  # Post-deploy: spaces created before the taxonomy migration still carry the legacy template
  # names ("🚌 Transport public"); the taxonomy renamed some nodes ("🚌 Transport en commun"),
  # leaving those spaces inconsistent with the picker's suggestions. Matches ONLY names the
  # system itself assigned (normalized legacy-template match) — anything the user typed or
  # edited is left alone. Three cases per matching row:
  #   • keyed row            -> renamed to the current taxonomy name
  #   • keyless row          -> adopted (template_key set) and renamed
  #   • space already has a row for that key -> duplicate: references are repointed onto the
  #     keyed row and the legacy row removed
  # Idempotent; any uniqueness conflict skips the row untouched.
  desc "Rename legacy template type names to current taxonomy names"
  task sync_template_names: :environment do
    renamed = merged = skipped = 0

    %w[en fr].each do |locale|
      I18n.t("transaction_type_templates", locale: locale, default: {}).each do |key, tpl|
        legacy_name = tpl[:name]
        target = TransactionTaxonomy.name(key.to_s, locale)
        next if legacy_name.blank? || target.blank? || legacy_name == target

        # Normalized comparison: rows were created from historical template wording, so the
        # emoji or punctuation may not match today's file exactly.
        TransactionType.where(template_key: [ nil, key.to_s ], kind: tpl[:kind])
                       .where.not(name: target).find_each do |type|
          next unless CategoryText.normalize(type.name) == CategoryText.normalize(legacy_name)

          owner = TransactionType.where(space_id: type.space_id, template_key: key.to_s)
                                 .where.not(id: type.id).first
          begin
            ActiveRecord::Base.transaction do
              if owner
                [ Transaction, BudgetEntry, BudgetItem ].each do |model|
                  model.where(transaction_type_id: type.id).update_all(transaction_type_id: owner.id)
                end
                TransactionType.where(parent_id: type.id).update_all(parent_id: owner.id)
                type.reload.destroy!
                merged += 1
              else
                type.update!(template_key: key.to_s, name: target)
                renamed += 1
              end
            end
          rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
            skipped += 1 # e.g. both types hold an active budget item, or a name collision
          end
        end
      end
    end

    puts "template names synced: #{renamed} renamed, #{merged} merged, #{skipped} skipped"
  end
end
