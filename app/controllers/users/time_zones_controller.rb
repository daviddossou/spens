# frozen_string_literal: true

# Stores the device's IANA time zone, posted by JS when it differs from the
# stored one (see time_zone_controller.js).
class Users::TimeZonesController < ApplicationController
  before_action :authenticate_user!

  def update
    zone = params[:time_zone].to_s
    current_user.update!(time_zone: zone) if Time.find_zone(zone)
    head :no_content
  end
end
