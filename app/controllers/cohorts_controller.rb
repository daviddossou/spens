# frozen_string_literal: true

# Sign-up page of the WhatsApp training cohort (spens.me/cohorte): one decision,
# join the group or leave. French only, served as its own lean document (no app
# CSS or JS: visitors come from Facebook ads on slow connections). The page is
# "open" while the active cohort takes members, "full" once a human closes it
# (cohorts:close); ?etat=complet previews the full state.
class CohortsController < ApplicationController
  layout false
  seo_indexable :show

  # Where the wait list writes once the cohort is full.
  WHATSAPP_NUMBER = "33689138559"
  WAITLIST_MESSAGE = "Bonjour David, je voudrais rejoindre la promo de décembre."

  before_action { I18n.locale = :fr }
  before_action :meta_issue_page_view_id
  after_action :meta_track_page_view

  def show
    @cohort = Cohort.current
    @full = params[:etat] == "complet" || !@cohort&.open?
    @group_url = @cohort&.whatsapp_group_url
    @waitlist_url = "https://wa.me/#{WHATSAPP_NUMBER}?text=#{ERB::Util.url_encode(WAITLIST_MESSAGE)}"
    # Server-issued dedup ids for the click events (pixel + CAPI).
    @meta_cohort_event_ids = {
      cohort_join: meta_issue_event_id(:cohort_join),
      cohort_waitlist: meta_issue_event_id(:cohort_waitlist)
    }
  end

  private

  def meta_issue_page_view_id
    @meta_page_view_id = meta_issue_event_id(:page_view)
  end

  def meta_track_page_view
    return unless response.successful?

    meta_send_server_event("PageView", event_id: @meta_page_view_id, user: current_user)
  end
end
