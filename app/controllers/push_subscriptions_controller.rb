# frozen_string_literal: true

# A browser's Web Push subscription, posted by push_controller.js once the user allowed
# notifications.
class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    keys = params.require(:subscription).permit(:endpoint, keys: %i[p256dh auth])
    PushSubscription.register(user: current_user, endpoint: keys[:endpoint], p256dh: keys.dig(:keys, :p256dh),
                              auth: keys.dig(:keys, :auth), user_agent: request.user_agent)
    head :created
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    head :unprocessable_entity
  end

  def destroy
    current_user.push_subscriptions.where(endpoint: params[:endpoint].to_s).destroy_all
    head :no_content
  end
end
