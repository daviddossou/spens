class LandingController < ApplicationController
  layout "marketing"

  def show
    return redirect_to dashboard_path if user_signed_in?
    # The Android app opens straight on sign-in; the landing is a web thing.
    redirect_to new_user_session_path if turbo_native_app?
  end
end
