# frozen_string_literal: true

require "rails_helper"

RSpec.describe Segments::FeedbackExporter do
  let(:now) { Time.zone.parse("2026-09-28 10:00") }
  let(:cutoff) { Date.new(2026, 9, 26) }
  let(:signup) { Time.zone.parse("2026-09-12 09:00") }

  def signed_up(email, at: signup)
    user = create(:user, email: email, confirmed_at: nil, first_name: "Ama")
    user.update_columns(created_at: at, updated_at: at, current_sign_in_at: nil, last_sign_in_at: nil)
    user.owned_spaces.update_all(created_at: at, updated_at: at, locale: "fr")
    user.memberships.update_all(created_at: at, updated_at: at)
    user
  end

  def export(**opts)
    described_class.new(cutoff: cutoff, now: now, **opts).call
  end

  it "puts a dormant user with nothing entered in segment A" do
    signed_up("a@gmail.com")

    result = export
    row = result.segments[:a].sole
    expect(row.values_at("email", "prenom", "locale", "pays", "date_inscription", "derniere_activite"))
      .to eq([ "a@gmail.com", "Ama", "fr", "BJ", "2026-09-12", "2026-09-12" ])
    expect(row.values_at("nb_comptes", "nb_transactions", "nb_lignes_budget", "nb_objectifs", "nb_dettes")).to all(eq(0))
    expect(result.segments[:b]).to be_empty
    expect(result.segments[:c]).to be_empty
  end

  it "puts a user who entered data on sign-up day and never came back in segment B" do
    user = signed_up("b@gmail.com")
    space = user.owned_spaces.first
    account = create(:account, user: user, space: space)
    opening = create(:transaction_type, space: space, kind: :initial_balance)
    transaction = create(:transaction, user: user, account: account, transaction_type: opening)
    [ account, transaction, space ].each { |r| r.update_columns(created_at: signup + 5.minutes, updated_at: signup + 5.minutes) }

    row = export.segments[:b].sole
    expect(row["nb_comptes"]).to eq(1)
    expect(row["nb_transactions"]).to eq(0)
  end

  it "puts a user who came back another day in segment C even when dormant now" do
    user = signed_up("c@gmail.com")
    user.update_columns(confirmed_at: signup + 2.days)

    expect(export.segments[:c].sole["derniere_activite"]).to eq("2026-09-14")
  end

  it "puts a recently active user in segment C" do
    user = signed_up("recent@gmail.com")
    user.update_columns(current_sign_in_at: now - 3.days)

    expect(export.segments[:c].sole["email"]).to eq("recent@gmail.com")
  end

  it "excludes test accounts and listed addresses, and leaves later sign-ups out of scope" do
    signed_up("dossoudavid00@gmail.com")
    signed_up("me@example.com")
    signed_up("bob+test@gmail.com")
    signed_up("dup@gmail.com")
    signed_up("late@gmail.com", at: Time.zone.parse("2026-09-27 08:00"))

    result = export(excluded_emails: [ "Dup@Gmail.com", "dossoudavid00@gmail.com" ])
    expect(result.segments.values.flatten).to be_empty
    expect(result.report).to include("Hors périmètre (créés après) : 1")
    expect(result.report).to include("adresse exclue 2", "compte de test 2")
  end

  it "flags domain typos without excluding them" do
    signed_up("typo@gmial.com")

    expect(export.segments[:a].sole["email_suspect"]).to eq("oui")
  end
end
