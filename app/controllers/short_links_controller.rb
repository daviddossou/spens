# frozen_string_literal: true

# Short redirects printed in the guide PDF (QR codes + inline links), e.g.
# spens.me/g/c. Keeping the mapping server-side means a destination can change
# without reprinting anything, and short URLs keep the QR codes sparse enough
# to scan at small sizes. Each redirect lands with the campaign UTMs plus
# guide_link, which the first-touch capture (MetaTracking) freezes in session —
# that's what tells us which chapter of the guide brings people to the app.
class ShortLinksController < ApplicationController
  UTM = { utm_source: "guide", utm_medium: "pdf", utm_campaign: "guide-septembre" }.freeze

  # code => [route helper, guide_link / utm_content]
  CODES = {
    "c" => [ :root_path, "couverture" ],           # cover QR
    "ps" => [ :new_user_registration_path, "ps-intro" ],
    "ch1" => [ :accounts_path, "action-ch1" ],     # comptes
    "ch2" => [ :dashboard_path, "action-ch2" ],    # mouvements
    "ch3" => [ :budgets_path, "action-ch3" ],
    "ch4" => [ :goals_path, "action-ch4" ],
    "ch5" => [ :goals_path, "action-ch5" ],
    "ch6" => [ :budgets_path, "action-ch6" ],
    "ch7" => [ :debts_path, "action-ch7" ],
    "ch8" => [ :analytics_path, "action-ch8" ],
    "ft" => [ :root_path, "pied-de-page" ],        # page footer
    "f" => [ :root_path, "fin" ]                   # last-page QR
  }.freeze

  def show
    helper, label = CODES[params[:code]]
    return redirect_to root_path unless helper

    track_click(label)
    redirect_to send(helper, **UTM, utm_content: label, guide_link: label)
  end

  private

  # Link-preview fetchers, not readers.
  PREVIEW_BOTS = /bot|crawl|spider|preview|facebookexternalhit|whatsapp|telegram|slack|discord/i

  def track_click(label)
    return if request.user_agent.to_s.match?(PREVIEW_BOTS)

    properties = { code: params[:code], guide_link: label, visitor: Digest::SHA256.hexdigest(session.id.to_s)[0, 16] }
    if current_user
      Analytics.track(current_user, "guide_link_opened", properties.merge(signed_in: true))
    else
      Analytics.track_anonymous("guide_link_opened", properties.merge(signed_in: false))
    end
  end
end
