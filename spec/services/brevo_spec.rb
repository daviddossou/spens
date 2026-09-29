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

  describe '.lifecycle_attributes' do
    it 'mirrors identity, dates, locale and source without money' do
      user = create(:user, first_name: 'Jane', last_name: nil, acquisition: { 'utm_source' => 'guide', 'guide_link' => 'action-ch1' })
      user.update_columns(created_at: Time.zone.parse('2026-09-12 09:00'), last_active_at: Time.zone.parse('2026-09-20 18:00'))
      user.owned_spaces.update_all(locale: 'fr', country: 'BJ')

      expect(described_class.lifecycle_attributes(user)).to eq(
        FIRSTNAME: 'Jane', SIGNED_UP_AT: '2026-09-12', LAST_ACTIVE_AT: '2026-09-20',
        LOCALE: 'fr', COUNTRY: 'BJ', SOURCE: 'action-ch1'
      )
    end
  end

  describe '.ensure_attributes' do
    it 'creates each attribute and treats an existing one as done' do
      allow(described_class).to receive(:enabled?).and_return(true)
      allow(Rails.logger).to receive(:warn)
      allow(described_class).to receive(:post_json) do |url, body|
        expect(url).to match(%r{/contacts/attributes/normal/[A-Z_]+\z})
        expect(body).to include(type: 'date').or include(type: 'text')
        instance_double(Net::HTTPBadRequest, code: '400', body: '{"code":"duplicate_parameter"}').tap do |r|
          allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        end
      end

      described_class.ensure_attributes

      expect(described_class).to have_received(:post_json).exactly(Brevo::ATTRIBUTES.size).times
      expect(Rails.logger).not_to have_received(:warn)
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
      allow(described_class).to receive(:config).and_return(enabled: true, api_key: 'k', list_ids: [ 7 ])
      allow(described_class).to receive(:post_json) do |_url, body|
        expect(body).to include(email: 'jane@example.com', updateEnabled: true, listIds: [ 7 ])
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
