# frozen_string_literal: true

module StatementImports
  # Captures are kept 90 days to check and improve the reading (privacy policy, section 6), then
  # deleted. The reads and lines stay: they are the user's own transactions data.
  class PurgeCapturesJob < ApplicationJob
    queue_as :default

    def perform
      StatementImport.where(created_at: ...StatementImport::CAPTURE_RETENTION.ago)
                     .joins(:captures_attachments).distinct.find_each { _1.captures.purge }
    end
  end
end
