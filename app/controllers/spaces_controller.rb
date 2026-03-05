# frozen_string_literal: true

class SpacesController < ApplicationController
  before_action :authenticate_user!

  def index
    @spaces = current_user.spaces.order(:name)
  end

  def new
    @space = current_user.spaces.new
  end

  def create
    @space = current_user.spaces.new(space_params)
    @space.onboarding_current_step = "onboarding_financial_goal"

    if @space.save
      set_current_space(@space)
      redirect_to onboarding_path, notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @space = current_user.spaces.find(params[:id])
    @can_delete = current_user.spaces.count > 1
  end

  def update
    @space = current_user.spaces.find(params[:id])

    if @space.update(space_params)
      redirect_to spaces_path, notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @space = current_user.spaces.find(params[:id])

    if current_user.spaces.count <= 1
      redirect_to spaces_path, alert: t(".last_space"), status: :see_other
      return
    end

    @space.destroy!

    # Switch to another space if the deleted one was active
    if current_space&.id == @space.id || current_space.nil?
      set_current_space(current_user.spaces.reload.first)
    end

    redirect_to spaces_path, notice: t(".success"), status: :see_other
  end

  private

  def space_params
    params.require(:space).permit(:name, :currency, :country)
  end
end
