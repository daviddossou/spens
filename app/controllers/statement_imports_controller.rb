# frozen_string_literal: true

# Tour 39: import up to 5 statement captures. The import is a draft while the captures and the
# account are chosen (39b), read in the background while the analysis screen polls, reviewed
# (39c), then saved with a toast that can undo it (39d). Every step is tracked (Tracking).
class StatementImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_access
  before_action :set_import, except: :create

  def create
    added = StatementImports::AddCaptures.call(params[:captures], room: StatementImport::MAX_CAPTURES)
    import = current_space.statement_imports.new(user: current_user, account: last_used_account, captures: added.blobs)

    if added.blobs.any? && import.save
      StatementImports::Tracking.started(import, origin: params[:origin], problem: added.problem)
      redirect_to statement_import_path(id: import.id), alert: helpers.statement_import_problem(added)
    else
      StatementImports::Tracking.rejected(current_user, origin: params[:origin], problem: added.problem || :unreadable)
      redirect_to dashboard_path, alert: helpers.statement_import_problem(added) || t("statement_imports.flash.unreadable")
    end
  end

  def show
    @account_rows = helpers.picker_account_rows(account_suggestions, current_space.currency) if @import.draft?
    return unless @import.ready?

    @category_rows = %w[expense income].index_with do |kind|
      helpers.picker_category_rows(TransactionTypeSuggestionsService.new(current_space, kind).options)
    end
  end

  # Polled by the analysis screen; also tells it where to go once everything is read.
  def progress
    render partial: "progress", locals: { import: @import }
  end

  def destroy
    StatementImports::Tracking.cancelled(@import)
    @import.destroy!
    redirect_to dashboard_path, status: :see_other
  end

  def analyze
    account = resolve_account(params.dig(:statement_import, :account_name))
    default_account = @import.account
    if @import.analyze!(account)
      StatementImports::Tracking.analyzed(@import, default_account: default_account)
      redirect_to statement_import_path(id: @import.id), status: :see_other
    else
      redirect_to statement_import_path(id: @import.id), status: :see_other, alert: t("statement_imports.flash.choose_account")
    end
  end

  # "Enregistrer N transactions": back to the account, with a toast that can undo the whole import.
  def save
    return redirect_to(statement_import_path(id: @import.id), status: :see_other) unless @import.ready?

    result = StatementImports::Save.call(@import)
    if result.invalid_lines.any?
      redirect_to statement_import_path(id: @import.id), status: :see_other,
                  alert: t("statement_imports.flash.lines_incomplete", count: result.invalid_lines.size)
    else
      StatementImports::Tracking.saved(@import, result)
      flash[:import_toast] = { "id" => @import.id, "count" => result.count,
                               "account" => @import.account && helpers.account_display_name(@import.account) }
      redirect_to(@import.account ? account_path(id: @import.account_id) : dashboard_path, status: :see_other)
    end
  end

  def undo
    removed = @import.transactions.count
    if StatementImports::Undo.call(@import)
      StatementImports::Tracking.undone(@import, removed: removed)
      redirect_to dashboard_path, status: :see_other, notice: t("statement_imports.flash.undone")
    else
      redirect_to dashboard_path, status: :see_other, alert: t("statement_imports.flash.undo_too_late")
    end
  end

  private

  def require_access
    head :not_found unless StatementImport.available_to?(current_user)
  end

  def set_import
    @import = current_space.statement_imports.where(user: current_user).find(params[:id])
  end

  # The account the user reaches for most recently: an import is almost always that one.
  def last_used_account
    id = current_space.transactions.where.not(account_id: nil).order(created_at: :desc).pick(:account_id)
    current_space.accounts.active.find_by(id: id) || current_space.accounts.active.order(:created_at).first
  end

  def resolve_account(name)
    return nil if name.blank?

    current_space.accounts.active.find_by("LOWER(name) = ?", name.strip.downcase) ||
      current_space.accounts.create(name: name.strip, user: current_user).then { _1 if _1.persisted? }
  end

  def account_suggestions
    current_space.accounts.active.map { |a| { name: a.name, balance: a.balance } }
  end
end
