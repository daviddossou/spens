# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:client) { instance_double(PostHog::Client, capture: true, group_identify: true) }

  before do
    allow(described_class).to receive(:client).and_return(client)
    Analytics::Context.reset
  end

  after { Analytics::Context.reset }

  it "merges the request context into the event and sets the space group" do
    Analytics::Context.platform = "native"
    Analytics::Context.locale = "fr"
    Analytics::Context.space_id = space.id

    described_class.track(user, "transaction_created", source: "manual")

    expect(client).to have_received(:capture).with(
      distinct_id: "user_#{user.id}", event: "transaction_created",
      properties: { platform: "native", locale: "fr", space_id: space.id, source: "manual" },
      groups: { space: space.id }
    )
  end

  it "sends no group outside a space" do
    described_class.track(user, "user_signed_in")

    expect(client).to have_received(:capture).with(hash_excluding(:groups))
  end

  it "tracks a resolved quick-entry attempt with its outcome and corrected fields, scoped to its space" do
    attempt = create(:quick_entry_attempt, user: user, space: space, outcome: "edited",
                     corrections: { "amount" => { "from" => 1, "to" => 2 } })

    described_class.track_quick_entry_resolved(attempt)

    expect(client).to have_received(:capture).with(
      hash_including(event: "quick_entry_resolved", groups: { space: space.id },
                     properties: hash_including(outcome: "edited", source: "rules", corrected_fields: [ "amount" ]))
    )
  end

  it "never raises when the client fails" do
    allow(client).to receive(:capture).and_raise(StandardError, "down")

    expect { described_class.track(user, "x") }.not_to raise_error
  end
end
