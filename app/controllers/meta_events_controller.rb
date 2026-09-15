# frozen_string_literal: true

# Receives browser beacons for pixel events that only the browser can observe
# (ViewContent after 30 s / scroll, Lead on download click) and doubles them
# server-side through the Conversions API. The event_id is never taken from the
# client: it was issued by the server at page render and lives in the session —
# the beacon only names which pending event fired.
class MetaEventsController < ApplicationController
  EVENTS = {
    "view_content" => "ViewContent",
    "lead_hero" => "Lead",
    "lead_final" => "Lead",
    "signup_start" => "spens_signup_start"
  }.freeze
  SIGNUP_PLACEMENTS = %w[nav hero diagnostic accounts pricing final].freeze

  rate_limit to: 30, within: 1.minute, only: :create

  def create
    event_name = EVENTS[params[:event]]
    event_id = meta_consume_event_id(params[:event])
    return head :unprocessable_entity unless event_name && event_id

    custom_data = {}
    custom_data[:content_name] = params[:event].delete_prefix("lead_") if event_name == "Lead"
    custom_data[:content_name] = params[:placement].presence_in(SIGNUP_PLACEMENTS) if event_name == "spens_signup_start"

    meta_send_server_event(event_name, event_id: event_id, user: current_user, custom_data: custom_data.compact)
    head :no_content
  end
end
