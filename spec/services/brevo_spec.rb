# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Brevo do
  describe '.upsert_contact_later' do
    context 'when enabled' do
      before { allow(described_class).to receive(:enabled?).and_return(true) }

      it 'enqueues a sync job with stringified attributes' do
        expect(BrevoContactSyncJob).to receive(:perform_later)
          .with('jane@example.com', { 'FIRSTNAME' => 'Jane' })

        described_class.upsert_contact_later(email: 'jane@example.com', attributes: { FIRSTNAME: 'Jane' })
      end
    end

    context 'when disabled' do
      before { allow(described_class).to receive(:enabled?).and_return(false) }

      it 'does not enqueue' do
        expect(BrevoContactSyncJob).not_to receive(:perform_later)
        described_class.upsert_contact_later(email: 'jane@example.com')
      end
    end

    it 'ignores a blank email' do
      allow(described_class).to receive(:enabled?).and_return(true)
      expect(BrevoContactSyncJob).not_to receive(:perform_later)
      described_class.upsert_contact_later(email: '')
    end
  end

  describe '.sync_contact' do
    it 'no-ops when disabled' do
      allow(described_class).to receive(:enabled?).and_return(false)
      expect(described_class).not_to receive(:post_json)
      expect(described_class.sync_contact('jane@example.com')).to be_nil
    end

    it 'posts an upsert body and swallows errors' do
      allow(described_class).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:config).and_return(enabled: true, api_key: 'k', list_ids: [7])
      allow(described_class).to receive(:post_json) do |_url, body|
        expect(body).to include(email: 'jane@example.com', updateEnabled: true, listIds: [7])
        instance_double(Net::HTTPCreated).tap { |r| allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }
      end

      described_class.sync_contact('jane@example.com', FIRSTNAME: 'Jane')
    end

    it 'returns nil and logs when the request raises' do
      allow(described_class).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:config).and_return(enabled: true, api_key: 'k', list_ids: [])
      allow(described_class).to receive(:post_json).and_raise(StandardError, 'boom')

      expect(described_class.sync_contact('jane@example.com')).to be_nil
    end
  end
end
