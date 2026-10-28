# frozen_string_literal: true

# Short links posted in the WhatsApp training group, e.g. spens.me/c/1. Each
# day's message has its own code, so the click log tells which message actually
# sends people into the app. The redirect lands on the screen the message asks
# for — not the home — with the cohort's UTMs for PostHog; a visitor who is not
# signed in gets there after signing in (ReturnPath). Link-preview fetchers get
# a generic Open Graph page instead of a redirect, and are not counted.
class CohortLinksController < ApplicationController
  # code => destination: a route helper (with params), :signup, or :join (the group).
  CODES = {
    "a" => :signup,                                  # welcome message
    "sim" => [ :landing_path, section: "calculator", anchor: "calculator" ], # 30 oct — the simulation
    "go" => :signup,                                 # 31 oct — we start tomorrow
    "1" => [ :new_account_path ],                    # J1 — accounts
    "2" => [ :new_transaction_path ],                # J2 — record a transaction
    "3" => [ :dashboard_path ],                      # J3 — transactions list, fix a category
    "4" => [ :new_budget_item_path, kind: "income" ], # J4 — income line, then an expense
    "5" => [ :budgets_path ],                        # J5 — budget
    "6" => [ :budgets_path ],                        # J6 — essential expenses total
    "7" => [ :new_goal_path ],                       # J7 — a goal
    "8" => [ :new_account_path ],                    # J8 — an account for the goal
    "9" => [ :new_transaction_path, kind: "transfer" ], # J9 — a transfer
    "10" => [ :budgets_path ],                       # J10 — the rest of the budget
    "11" => [ :debts_path ],                         # J11 — debts
    "bilan" => [ :budgets_path, view: "wrap_up" ],   # end of month — planned vs actual
    "join" => :join                                  # group invitation, outside the sign-up page
  }.freeze

  UTM = { utm_source: "whatsapp", utm_medium: "groupe" }.freeze

  # Link-preview fetchers, not readers.
  PREVIEW_BOTS = /bot|crawl|spider|preview|facebookexternalhit|whatsapp|telegram|slack|discord/i

  def show
    destination = CODES[params[:code]]
    return redirect_to root_path unless destination
    return render_preview if preview_bot?

    cohort = Cohort.current
    log_click(cohort)

    case destination
    when :join then redirect_to_group(cohort)
    when :signup then redirect_to new_user_registration_path(**utm(cohort))
    else redirect_to_screen(destination, cohort)
    end
  end

  private

  # The group is French-speaking: the card reads French unless the link says otherwise.
  def render_preview
    I18n.with_locale(params[:locale].presence || :fr) { render :preview, layout: false }
  end

  def preview_bot?
    request.user_agent.to_s.match?(PREVIEW_BOTS)
  end

  def utm(cohort)
    UTM.merge(utm_campaign: cohort&.campaign || "cohorte", utm_content: params[:code])
  end

  PUBLIC = %i[landing_path].freeze

  # Signed in (or a public page): straight to the screen. Otherwise sign in
  # first, the screen is remembered; the UTMs ride on the sign-in page so
  # PostHog still sees them.
  def redirect_to_screen((helper, options), cohort)
    options ||= {}
    if user_signed_in? || PUBLIC.include?(helper)
      redirect_to send(helper, **options, **utm(cohort))
    else
      remember_return_path(send(helper, **options))
      redirect_to new_user_session_path(**utm(cohort))
    end
  end

  def redirect_to_group(cohort)
    url = cohort&.whatsapp_group_url
    return redirect_to root_path if url.blank?

    redirect_to url, allow_other_host: true
  end

  def log_click(cohort)
    ShortLinkClick.create!(code: params[:code], campaign: cohort&.campaign, user: current_user,
                           user_agent: request.user_agent&.first(500), referer: request.referer&.first(500))
    properties = { code: params[:code], campaign: cohort&.campaign, signed_in: user_signed_in? }
    if current_user
      Analytics.track(current_user, "cohort_link_opened", properties)
    else
      Analytics.track_anonymous("cohort_link_opened", properties)
    end
  end
end
