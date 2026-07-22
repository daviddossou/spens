# frozen_string_literal: true

class SpacesController < ApplicationController
  before_action :authenticate_user!

  def index
    @spaces = current_user.spaces.order(:name)
  end

  def new
    @space = Space.new
  end

  def create
    @space = Space.new(space_params.merge(user: current_user))
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

    unless @space.user == current_user
      redirect_to spaces_path, alert: t(".not_owner"), status: :see_other
      return
    end

    if current_user.spaces.count <= 1
      redirect_to spaces_path, alert: t(".last_space"), status: :see_other
      return
    end

    was_active = session[:current_space_id] == @space.id

    @space.destroy!

    # If the deleted space was the active one, switch to a remaining space.
    # Compare against the stored session id rather than current_space, which
    # silently falls back to another space and would mask the deletion.
    if was_active
      set_current_space(current_user.spaces.reload.first)
    end

    redirect_to spaces_path, notice: t(".success"), status: :see_other
  end

  private

  def space_params
    params.require(:space).permit(:name, :currency, :country, :monthly_savings_goal)
  end
end
