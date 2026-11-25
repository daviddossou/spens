# frozen_string_literal: true

module StatementImportsHelper
  # Why some files were left out of an import, or nil.
  def statement_import_problem(added)
    case added.problem
    when :unreadable then t("statement_imports.flash.unreadable")
    when :pdf_too_long then t("statement_imports.flash.pdf_too_long", pages: added.pages, count: added.room)
    end
  end

  # "2 captures · Banque"
  def statement_import_subtitle(import)
    parts = [ t("statement_imports.captures_count", count: import.captures.size) ]
    parts << account_display_name(import.account) if import.account
    parts.join(" · ")
  end

  def account_display_name(account)
    account.name.sub(/\A[^[:alnum:]]+/, "").strip
  end

  # "− 20,13 €" / "+ 15,36 €", in the line's own currency when it differs.
  def statement_line_amount(line, space)
    money(line.amount, line.currency.presence || space.currency, sign: :always)
  end

  def statement_line_date(line)
    line.occurred_on ? l(line.occurred_on, format: :day_month_short) : t("statement_imports.review.no_date")
  end

  # The note under a line to review, in the user's words.
  def statement_line_note(line, space)
    reason = line.review_reason or return nil
    existing = line.existing_transaction
    t("statement_imports.review.reasons.#{reason}",
      date: existing ? l(existing.transaction_date, format: :day_month_short) : "",
      currency: line.currency, space_currency: get_currency_symbol(space.currency))
  end

  def statement_ignored_reason(line)
    t("statement_imports.review.ignored.#{line.ignored_reason}", default: t("statement_imports.review.ignored.duplicate"))
  end

  # Totals of the ticked lines, money out and money in (transfers move nothing).
  def statement_import_totals(lines)
    included = lines.select { _1.proposed? && _1.included? && !_1.kind.to_s.start_with?("transfer") }
    out, into = included.partition(&:money_out?)
    [ out.sum { _1.amount.abs }, into.sum { _1.amount.abs } ]
  end
end
