# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::DiagnosticComponent, type: :component do
  let(:accents) { %w[--color-primary --color-success-dark --color-warning-dark --color-info-dark --color-violet --color-danger-dark] }
  let(:goals) { %w[save_regularly cut_wasteful_spending track_spending track_all_accounts track_repayments pay_off_debt] }
  let(:rendered) { render_inline(described_class.new(diagnostic_accents: accents, diagnostic_goals: goals)) }
  let(:section) { rendered.at_css("section.landing-sect") }

  it "hands the section to the diagnostic controller and marks it as a milestone for Meta" do
    expect(section["data-controller"]).to eq("landing--diagnostic")
    expect(section["data-landing--meta-events-target"]).to eq("milestone")
  end

  it "carries every recap tier, translated, as a JSON value" do
    tiers = JSON.parse(section["data-landing--diagnostic-tiers-value"])
    expect(tiers.keys).to eq(%w[none low mid high])
    expect(tiers["high"]).to eq("title" => I18n.t("landing.diagnostic.tiers.high.title"), "line" => I18n.t("landing.diagnostic.tiers.high.line"))
  end

  it "renders one toggle per problem, unpressed, mapped to an onboarding goal and an accent" do
    cards = section.css("button.landing-diag")
    expect(cards.size).to eq(6)
    expect(cards.map { |c| c["type"] }.uniq).to eq([ "button" ])
    expect(cards.map { |c| c["aria-pressed"] }.uniq).to eq([ "false" ])
    expect(cards.map { |c| c["data-action"] }.uniq).to eq([ "landing--diagnostic#toggle" ])
    expect(cards.map { |c| c["data-landing--diagnostic-target"] }.uniq).to eq([ "card" ])
    expect(cards.map { |c| c["data-goals"] }).to eq(goals)
    expect(cards.map { |c| c["style"] }).to eq(accents.map { |a| "--accent: var(#{a});" })
    expect(cards.map { |c| c.at_css(".landing-diag__text").text }).to eq(I18n.t("landing.diagnostic.items"))
  end

  it "hides the decorative checkbox from assistive tech" do
    expect(section.css(".landing-diag__box").map { |b| b["aria-hidden"] }.uniq).to eq([ "true" ])
  end

  it "starts the recap on the empty tier and announces changes politely" do
    expect(section.at_css('[data-landing--diagnostic-target="count"]').text).to eq("0")
    expect(section.at_css('[data-landing--diagnostic-target="count"]')["aria-hidden"]).to eq("true")
    title = section.at_css('[data-landing--diagnostic-target="title"]')
    expect(title["aria-live"]).to eq("polite")
    expect(title.text).to eq(I18n.t("landing.diagnostic.tiers.none.title"))
    expect(section.at_css('[data-landing--diagnostic-target="line"]').text).to eq(I18n.t("landing.diagnostic.tiers.none.line"))
  end

  it "sends the sign-up CTA through the Meta events controller with its placement" do
    cta = section.at_css("a.landing-btn-light")
    expect(cta["href"]).to eq("/sign_up")
    expect(cta["data-action"]).to eq("landing--meta-events#signup")
    expect(cta["data-landing--meta-events-placement-param"]).to eq("diagnostic")
    expect(cta.text.strip).to eq(I18n.t("landing.diagnostic.cta"))
  end

  %i[fr en].each do |locale|
    it "reads fully in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new(diagnostic_accents: accents, diagnostic_goals: goals))
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css("h2.landing-h2").text).to eq(I18n.t("landing.diagnostic.title"))
        expect(html.css("button.landing-diag").size).to eq(6)
      end
    end
  end
end
