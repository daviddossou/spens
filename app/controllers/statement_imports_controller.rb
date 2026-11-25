# frozen_string_literal: true

# Tour 39: import up to 5 statement captures. The import is a draft while the captures and the
# account are chosen (39b), then read in the background while the analysis screen polls.
class StatementImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_access
  before_action :set_import, except: :create

def create
  added = StatementImports::AddCaptures.call(params[:captures], room: StatementImport::MAX_CAPTURES)
  import = current_space.statement_imports.new(user: current_user, account: last_used_account, captures: added.blobs)

  if added.blobs.any? && import.save
    redirect_to statement_import_path(id: import.id), alert: helpers.statement_import_problem(added)
  else
    redirect_to dashboard_path, alert: helpers.statement_import_problem(added) || t("statement_imports.flash.unreadable")
  end
end

  def show
    @account_rows = helpers.picker_account_rows(account_suggestions, current_space.currency)
  end

  # Polled by the analysis screen; also tells it where to go once everything is read.
  def progress
    render partial: "progress", locals: { import: @import }
  end

  def destroy
    @import.destroy!
    redirect_to dashboard_path, status: :see_other
  end

  def analyze
    account = resolve_account(params.dig(:statement_import, :account_name))
    if @import.analyze!(account)
      redirect_to statement_import_path(id: @import.id), status: :see_other
    else
      redirect_to statement_import_path(id: @import.id), status: :see_other, alert: t("statement_imports.flash.choose_account")
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
