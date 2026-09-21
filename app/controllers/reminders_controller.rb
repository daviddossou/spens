# frozen_string_literal: true

# The current member's reminder for the current space: accepted, declined or re-timed from
# the onboarding card, the dashboard suggestion and the space settings. The e-mail's
# "stop" link lands here too, signed, without a session.
class RemindersController < ApplicationController
  before_action :authenticate_user!, only: :update
  skip_before_action :verify_authenticity_token, only: :stop

  def update
    if params[:decline].present?
      membership.decline_reminder!
      track("declined")
    elsif ActiveModel::Type::Boolean.new.cast(setting(:enabled))
      membership.enable_reminder!(hour: chosen_hour)
      track("enabled")
    else
      membership.update!({ reminder_enabled: false, reminder_hour: chosen_hour }.compact)
      track("disabled")
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("reminder_card", partial: "reminders/card", locals: card_locals) }
      format.html { redirect_back fallback_location: dashboard_path, status: :see_other }
    end
  end

  # GET shows a confirmation (mail clients prefetch links); POST stops the reminder.
  def unsubscribe
    @token = params[:token]
    @membership = Membership.find_signed(@token, purpose: :reminder)
    render layout: "auth"
  end

  def stop
    @membership = Membership.find_signed(params[:token], purpose: :reminder)
    @membership&.update!(reminder_enabled: false)
    @stopped = true
    render :unsubscribe, layout: "auth"
  end

  private

  # The settings page edits any of the user's spaces; the cards act on the current one.
  def membership
    @membership ||= current_user.memberships.find_by!(space_id: params[:space_id].presence || current_space.id)
  end

  # Cards post flat params; the settings form posts them under its model.
  def setting(name)
    params[name] || params.dig(:membership, :"reminder_#{name}")
  end

  def chosen_hour
    hour = Integer(setting(:hour), exception: false)
    hour if hour&.between?(0, 23)
  end

  def card_locals
    { membership: membership, source: params[:source].presence_in(%w[onboarding habit]) || "onboarding", suggested_hour: nil }
  end

  def track(action)
    Analytics.track(current_user, "reminder_#{action}", source: params[:source].to_s.presence, hour: membership.reminder_hour)
  end
end
