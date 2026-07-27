# frozen_string_literal: true

namespace :transaction_types do
  # Post-deploy: spaces created before the taxonomy migration still carry the legacy template
  # names ("🚌 Transport public"); the taxonomy renamed some nodes ("🚌 Transport en commun"),
  # leaving those spaces inconsistent with the picker's suggestions. Renames ONLY names the
  # system itself assigned (exact legacy template match on a template-keyed type) — anything
  # the user typed or edited is left alone. Idempotent; skips name collisions.
  desc "Rename template-keyed types from legacy template names to current taxonomy names"
  task sync_template_names: :environment do
    renamed = skipped = 0

    %w[en fr].each do |locale|
      I18n.t("transaction_type_templates", locale: locale, default: {}).each do |key, tpl|
        legacy_name = tpl[:name]
        target = TransactionTaxonomy.name(key.to_s, locale)
        next if legacy_name.blank? || target.blank? || legacy_name == target

        # Normalized comparison: rows were created from historical template wording, so the
        # emoji or punctuation may not match today's file exactly.
        TransactionType.where(template_key: key.to_s).where.not(name: target).find_each do |type|
          next unless CategoryText.normalize(type.name) == CategoryText.normalize(legacy_name)

          type.update(name: target) ? renamed += 1 : skipped += 1
        end
      end
    end

    puts "template names synced: #{renamed} renamed, #{skipped} skipped (collisions)"
  end
end
