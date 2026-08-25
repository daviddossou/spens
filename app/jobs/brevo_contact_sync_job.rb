# frozen_string_literal: true

# Pushes a contact into Brevo off the request thread. Best-effort: Brevo.sync_contact swallows
# its own errors, so a Brevo outage never poisons the queue.
class BrevoContactSyncJob < ApplicationJob
  queue_as :default

  def perform(email, attributes = {})
    Brevo.sync_contact(email, attributes)
  end
end
