# frozen_string_literal: true

module StatementImports
  # The review list: set a line's category in one tap, ignore or keep it, bring back a line set
  # aside, or edit it in the usual transaction form. Nothing here creates a transaction.
  class LinesController < ApplicationController
    before_action :authenticate_user!
    before_action -> { head :not_found unless StatementImport.available_to?(current_user) }
    before_action :set_import
    before_action :set_line
    helper_method :carried_params

    # An amount in another currency is never carried into the form: the user types it in the
    # space currency, the original stays shown above.
    def edit
      payload = @line.payload.symbolize_keys
      payload.delete(:amount) if @line.flags.include?("foreign_currency")
      build_form(payload.merge(carried_params))
    end

    def update
      if params[:transaction]
        build_form(@line.payload.symbolize_keys.merge(transaction_params))
        return render(:edit, status: :unprocessable_entity) unless @form.valid?

        @line.apply_form!(@form)
        Tracking.line_changed(@line, change: "edited")
        redirect_to statement_import_path(id: @import.id), status: :see_other
      else
        from_source = @line.category_source
        @line.update!(line_params)
        if line_params.key?(:transaction_type_name)
          @line.update!(category_source: "user", flags: @line.flags | [ "category_changed" ])
          Tracking.line_changed(@line, change: "category", from_source: from_source)
        end
        render_review_streams
      end
    end

    def restore
      if @line.addable?
        reason = @line.ignored_reason
        @line.restore!
        Tracking.line_changed(@line, change: "restored", from_source: reason)
      end
      render_review_streams(open_ignored: true)
    end

    # Swiped away, or "Ignorer" on a likely duplicate, an amount in another currency, or in the
    # edit sheet: out of the list and the totals, back with "Ajouter".
    def ignore
      @line.remove!
      Tracking.line_changed(@line, change: "ignored", from_source: params[:via].presence || "button")
      return redirect_to(statement_import_path(id: @import.id), status: :see_other) if params[:via] == "form"

      render_review_streams
    end

    # "Garder quand même" on a likely duplicate.
    def keep
      @line.keep!
      Tracking.line_changed(@line, change: "kept")
      render_review_streams
    end

    private

    def set_import
      @import = current_space.statement_imports.where(user: current_user, status: "ready").find(params[:statement_import_id])
    end

    def set_line
      @line = @import.lines.find(params[:id])
    end

    def line_params
      params.require(:line).permit(:transaction_type_name)
    end

    def transaction_params
      params.require(:transaction).permit(*StatementImportLine::FORM_FIELDS, :amount, :debt_id).to_h.symbolize_keys
    end

    # A kind switch reloads the form with what was typed so far.
    CARRIED_KEYS = %i[kind amount account_name from_account_name to_account_name transaction_type_name
                      contact_name direction debt_id].freeze
    def carried_params
      CARRIED_KEYS.index_with { |key| params[key] }.compact_blank
    end

    def build_form(payload)
      @form = TransactionForm.new(current_space, payload)
      @form.user = current_user
      @filled_fields = []
    end

    # The list, the totals and the save button all follow the change.
    def render_review_streams(open_ignored: false)
      @import.lines.reload
      render turbo_stream: turbo_stream.replace("statement_import_review", partial: "statement_imports/review",
                                                                            locals: { import: @import, open_ignored: open_ignored })
    end
  end
end
