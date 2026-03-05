# frozen_string_literal: true

module SpaceScoping
  extend ActiveSupport::Concern

  included do
    helper_method :current_space
  end

  def current_space
    return nil unless user_signed_in?

    @current_space ||= begin
      if session[:current_space_id]
        current_user.spaces.find_by(id: session[:current_space_id]) || current_user.spaces.first
      else
        current_user.spaces.first
      end
    end
  end

  def set_current_space(space)
    session[:current_space_id] = space&.id
    @current_space = space
  end
end
