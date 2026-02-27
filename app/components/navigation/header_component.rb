# frozen_string_literal: true

class Navigation::HeaderComponent < ViewComponent::Base
  include UserHelper

  attr_reader :page_title, :current_user, :params

  def initialize(page_title: nil, current_user:, params: {})
    @page_title = page_title
    @current_user = current_user
    @params = params
  end

  def user_initials
    first = current_user.first_name.to_s[0] || ""
    last = current_user.last_name.to_s[0] || ""
    initials = "#{first}#{last}".upcase
    initials.present? ? initials : "?"
  end

  def user_full_name
    user_display_name(current_user)
  end

  def user_email
    current_user.email
  end

  def settings_path
    helpers.edit_user_registration_path
  end

  def logout_path
    helpers.destroy_user_session_path
  end

  def analytics_path
    helpers.dashboard_path
  end
end
