# frozen_string_literal: true

# Meta (Facebook) Pixel + Conversions API. Every browser pixel event is doubled
# server-side with the same event_id so Meta deduplicates; activation events are
# server-only. Keys live in Rails credentials (meta.pixel_id, meta.capi_token);
# ENV overrides for local/staging. Off unless configured, so dev/test never send.
# META_TEST_EVENT_CODE routes CAPI events to the Events Manager test tab.
pixel_id = ENV["META_PIXEL_ID"].presence || Rails.application.credentials.dig(:meta, :pixel_id)
capi_token = ENV["META_CAPI_TOKEN"].presence || Rails.application.credentials.dig(:meta, :capi_token)

Rails.application.config.x.meta = {
  pixel_id: pixel_id,
  capi_token: capi_token,
  test_event_code: ENV["META_TEST_EVENT_CODE"].presence,
  pixel_enabled: pixel_id.present?,
  capi_enabled: pixel_id.present? && capi_token.present?
}
