class LandingController < ApplicationController
  layout "marketing"
  seo_indexable :show, :guide, :download

  before_action :meta_issue_page_view_id, only: [ :show, :guide, :guide_thanks, :download ]
  after_action :meta_track_page_view, only: [ :show, :guide, :guide_thanks, :download ]

  def show
    # A link to one section of the page (the calculator, from the cohort links)
    # is for members too: only a plain visit by a member goes to the dashboard.
    return redirect_to dashboard_path if user_signed_in? && params[:section].blank?
    # The Android app opens straight on sign-in; the landing is a web thing.
    return redirect_to new_user_session_path if turbo_native_app?

    # Server-issued dedup ids for the browser-triggered events on this page.
    @meta_landing_event_ids = {
      view_content: meta_issue_event_id(:view_content),
      signup_start: meta_issue_event_id(:signup_start)
    }
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

  # Install page for the PWA: per-device steps, a QR code for desktop visitors.
  def download
    return redirect_to root_path if turbo_native_app?

    @download_url = helpers.seo_origin + download_path(locale: I18n.locale)
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
