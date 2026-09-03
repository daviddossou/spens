class LandingController < ApplicationController
  layout "marketing"

  before_action :meta_issue_page_view_id, only: [ :show, :guide, :guide_thanks ]
  after_action :meta_track_page_view, only: [ :show, :guide, :guide_thanks ]

  def show
    return redirect_to dashboard_path if user_signed_in?
    # The Android app opens straight on sign-in; the landing is a web thing.
    redirect_to new_user_session_path if turbo_native_app?
  end

  # Lead-magnet page for the free savings guide (PDF download, no email gate).
  def guide
    # Server-issued dedup ids for the browser-triggered events on this page.
    @meta_guide_event_ids = {
      view_content: meta_issue_event_id(:view_content),
      lead_hero: meta_issue_event_id(:lead_hero),
      lead_final: meta_issue_event_id(:lead_final)
    }
  end

  # Shown after the guide download starts: bridges the guide's actions into Spens.
  def guide_thanks
  end

  private

  # PageView on both channels with one shared id: the pixel fires it from the
  # shared/meta_pixel partial, the CAPI send goes out once the page rendered.
  def meta_issue_page_view_id
    @meta_page_view_id = meta_issue_event_id(:page_view)
  end

  def meta_track_page_view
    return unless response.successful?

    meta_send_server_event("PageView", event_id: @meta_page_view_id, user: current_user)
  end
end
