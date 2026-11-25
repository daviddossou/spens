# frozen_string_literal: true

module StatementImports
  # Adds or removes captures on a draft import (39b): never more than 5 slots.
  class CapturesController < ApplicationController
    before_action :authenticate_user!
    before_action -> { head :not_found unless StatementImport.available_to?(current_user) }
    before_action :set_import

    def create
      added = AddCaptures.call(params[:captures], room: @import.room_left)
      @import.captures.attach(added.blobs) if added.blobs.any?
      Tracking.captures_changed(@import, change: "added", problem: added.problem)
      redirect_to statement_import_path(id: @import.id), status: :see_other, alert: helpers.statement_import_problem(added)
    end

    def destroy
      @import.captures.find(params[:id]).purge
      Tracking.captures_changed(@import.reload, change: "removed")
      redirect_to statement_import_path(id: @import.id), status: :see_other
    end

    private

    def set_import
      @import = current_space.statement_imports.where(user: current_user, status: "draft").find(params[:statement_import_id])
    end
  end
end
