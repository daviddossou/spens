# frozen_string_literal: true

# Sends one Conversions API event off the request thread. Best-effort: Meta.deliver
# swallows its own errors, so a Meta outage never poisons the queue.
class MetaEventJob < ApplicationJob
  queue_as :default

  def perform(event)
    Meta.deliver(event)
  end
end
