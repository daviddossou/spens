# frozen_string_literal: true

class Users::ProfileController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t("auth.profile.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.destroy
    sign_out
    redirect_to root_path, notice: t("auth.profile.destroyed")
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
