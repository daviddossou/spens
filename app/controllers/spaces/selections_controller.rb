# frozen_string_literal: true

class Spaces::SelectionsController < ApplicationController
  before_action :authenticate_user!

  def create
    space = current_user.spaces.find(params[:space_id])
    set_current_space(space)
    redirect_to dashboard_path, notice: t(".success", name: space.name), status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to spaces_path, alert: t(".not_found")
  end
end
