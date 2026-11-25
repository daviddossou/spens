# frozen_string_literal: true

module StatementImports
  # Every step of an import, as PostHog events (statement_import_*): what people send (files,
  # images or PDFs, pages), how well we read it (lines, set-aside reasons, duplicates, tokens),
  # how well we classify it (category rules / AI / Other), and what the user changes before
  # saving. Counts and categories only: no amounts, labels or file names.
  module Tracking
    module_function

    def started(import, origin:, problem: nil)
      track(import, "statement_import_started", origin: origin.presence || "unknown", problem: problem&.to_s, **files(import))
    end

    def rejected(user, origin:, problem:)
      Analytics.track(user, "statement_import_rejected", origin: origin.presence || "unknown", problem: problem.to_s)
    end

    def captures_changed(import, change:, problem: nil)
      track(import, "statement_import_captures_changed", change: change, problem: problem&.to_s, **files(import))
    end

    def analyzed(import, default_account:)
      track(import, "statement_import_analyzed", account_changed: import.account_id != default_account&.id, **files(import))
    end

    def read(import, seconds:)
      track(import, "statement_import_read", status: import.status, seconds: seconds.round(1), **files(import), **reads(import), **lines(import))
    end

    def untick_all(import)
      track(import, "statement_import_line_changed", change: "untick_all")
    end

    def line_changed(line, change:, from_source: nil)
      track(line.statement_import, "statement_import_line_changed",
            change: change, kind: line.kind, from_source: from_source, review_reason: line.review_reason)
    end

    def saved(import, result)
      lines = import.lines.to_a
      kept = lines.select { _1.decision == "accepted" }
      minutes = import.saved_at && ((import.saved_at - import.created_at) / 60).round(1)
      track(import, "statement_import_saved",
            count: result.count, minutes_to_save: minutes, **files(import),
            proposed: lines.count(&:proposed?),
            unticked: lines.count { _1.proposed? && _1.decision == "skipped" },
            edited: kept.count { _1.flags.include?("edited") },
            restored: kept.count { _1.flags.include?("restored") },
            category_changed: kept.count { _1.flags.include?("category_changed") },
            foreign_fixed: kept.count { _1.extracted["currency"].present? && _1.extracted["currency"].upcase != import.space.currency },
            kinds: kept.map(&:kind).tally,
            **result.categories.symbolize_keys)
    end

    def undone(import, removed:)
      track(import, "statement_import_undone", removed: removed, seconds_after_save: (Time.current - import.saved_at).round)
    end

    def cancelled(import)
      track(import, "statement_import_cancelled", status: import.status, **files(import))
    end

    # What was sent: how many files, of which kind, how many PDF pages.
    def files(import)
      blobs = import.captures.map(&:blob)
      pdfs = blobs.select { _1.content_type == "application/pdf" }
      { files: blobs.size, images: blobs.size - pdfs.size, pdfs: pdfs.size,
        pdf_pages: pdfs.sum { _1.metadata.fetch("pages", 1).to_i }, slots: import.slots_used }
    end

    # How the model read it: failures, time, cost, the source it recognised.
    def reads(import)
      reads = Array(import.reads)
      usage = reads.filter_map { _1["usage"] }
      { model: import.model, captures_failed: reads.count { _1["error"] },
        read_seconds: reads.sum { _1["seconds"].to_f }.round(1),
        input_tokens: usage.sum { _1["input_tokens"].to_i }, output_tokens: usage.sum { _1["output_tokens"].to_i },
        detected_source: import.source }
    end

    # What our rules made of it: what is proposed, what is set aside and why, how it is classified.
    def lines(import)
      lines = import.lines.to_a
      proposed = lines.select(&:proposed?)
      categorised = proposed.select(&:category_kind?)
      {
        lines_read: lines.size, lines_proposed: proposed.size,
        to_review: proposed.count(&:review_reason),
        review_reasons: proposed.filter_map(&:review_reason).tally,
        ignored_reasons: lines.reject(&:proposed?).map(&:ignored_reason).tally,
        kinds: proposed.map(&:kind).tally,
        rule_flags: proposed.flat_map(&:flags).tally,
        category_rules: categorised.count { _1.category_source == "rules" },
        category_ai: categorised.count { _1.category_source == "ai" },
        category_fallback: categorised.count { _1.category_source == "fallback" },
        category_none: categorised.count { _1.transaction_type_name.blank? },
        foreign_currency: proposed.count { _1.flags.include?("foreign_currency") },
        already_in_spens: proposed.count(&:existing_transaction_id)
      }
    end

    def track(import, event, properties)
      Analytics::Context.set(space_id: import.space_id) do
        Analytics.track(import.user, event, properties.compact)
      end
    end
  end
end
