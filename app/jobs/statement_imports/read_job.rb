# frozen_string_literal: true

module StatementImports
  # Reads every capture in parallel (the user is waiting on the analysis screen), keeps each raw
  # read, then builds the proposals. A capture that fails is recorded and skipped; the import only
  # fails when nothing could be read.
  class ReadJob < ApplicationJob
    queue_as :default

    def perform(import_id)
      import = StatementImport.find_by(id: import_id) or return
      return unless import.reading?

      reader = Reader.new(space: import.space, user: import.user, account: import.account)
      # Blobs are loaded up front: the threads only download and call the API.
      reads = import.captures.includes(:blob).map(&:blob).each_with_index.map do |blob, index|
        Thread.new { read_one(reader, blob, index) }
      end.map(&:value)

      import.update!(reads: reads, model: Reader.config[:model])
      if reads.none? { _1["result"] }
        import.update!(status: "failed", error: reads.filter_map { _1["error"] }.uniq.join("; "))
      else
        Proposer.call(import)
        import.update!(status: "ready")
      end
    rescue StandardError => e
      import&.update_columns(status: "failed", error: e.message.truncate(500)) # rubocop:disable Rails/SkipsModelValidations
      raise
    end

    private

    def read_one(reader, blob, index)
      Rails.application.executor.wrap do
        reader.read(blob).merge("capture_index" => index, "blob_id" => blob.id)
      end
    rescue StandardError => e
      Rails.logger.warn("StatementImports::ReadJob capture #{index} failed: #{e.message}")
      { "capture_index" => index, "blob_id" => blob.id, "error" => e.message.truncate(300) }
    end
  end
end
