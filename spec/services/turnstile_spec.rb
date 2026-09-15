# frozen_string_literal: true

require "rails_helper"

RSpec.describe Turnstile do
  let(:config) { { site_key: "site", secret_key: "secret", enabled: true } }

  before { allow(described_class).to receive(:config).and_return(config) }

  it "passes everything when disabled" do
    config[:enabled] = false
    expect(described_class).not_to receive(:siteverify)
    expect(described_class.verify(nil).success?).to be true
  end

  it "rejects a missing token without calling Cloudflare" do
    expect(described_class).not_to receive(:siteverify)
    result = described_class.verify("")
    expect(result.success?).to be false
    expect(result.error_codes).to eq([ "missing-input-response" ])
  end

  it "accepts a token siteverify approves" do
    allow(described_class).to receive(:siteverify)
      .with(response: "tok", secret: "secret", remoteip: "1.2.3.4")
      .and_return({ "success" => true })
    expect(described_class.verify("tok", ip: "1.2.3.4").success?).to be true
  end

  it "rejects a token siteverify refuses, keeping the error codes" do
    allow(described_class).to receive(:siteverify).and_return({ "success" => false, "error-codes" => [ "timeout-or-duplicate" ] })
    result = described_class.verify("tok")
    expect(result.success?).to be false
    expect(result.error_codes).to eq([ "timeout-or-duplicate" ])
  end

  it "fails open when siteverify is unreachable" do
    allow(described_class).to receive(:siteverify).and_raise(Net::OpenTimeout)
    result = described_class.verify("tok")
    expect(result.success?).to be true
    expect(result.error_codes).to eq([ "siteverify-unreachable" ])
  end
end
