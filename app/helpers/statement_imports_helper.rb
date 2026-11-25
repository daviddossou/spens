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
    parts << import.account.name.sub(/\A[^[:alnum:]]+/, "").strip if import.account
    parts.join(" · ")
  end
end
