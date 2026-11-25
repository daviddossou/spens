# frozen_string_literal: true

module StatementImports
  # Reads every capture in parallel and saves each read as soon as it lands, so the analysis
  # screen can show the captures finishing one by one. A capture that fails is recorded and
  # skipped; the import only fails when nothing could be read. If the user cancels (the import
  # is deleted) while reading, the job just stops.
  class ReadJob < ApplicationJob
    queue_as :default

    def perform(import_id)
      import = StatementImport.find_by(id: import_id) or return
      return unless import.reading?

      reader = Reader.new(space: import.space, user: import.user, account: import.account)
      # Blobs are loaded up front: the threads only download and call the API.
      blobs = import.captures.includes(:blob).map(&:blob)
      results = Queue.new
      threads = blobs.each_with_index.map { |blob, index| Thread.new { results << read_one(reader, blob, index) } }

      blobs.size.times do
        read = results.pop
        return unless StatementImport.exists?(import.id)

        import.update!(reads: import.reads + [ read ], model: Reader.config[:model])
      end
      threads.each(&:join)

      finish(import)
    rescue ActiveRecord::RecordNotFound, ActiveRecord::StaleObjectError
      nil
    rescue StandardError => e
      import.update_columns(status: "failed", error: e.message.truncate(500)) if import && StatementImport.exists?(import.id) # rubocop:disable Rails/SkipsModelValidations
      raise
    end

    private

    def finish(import)
      if import.reads.none? { _1["result"] }
        import.update!(status: "failed", error: import.reads.filter_map { _1["error"] }.uniq.join("; "))
      else
        Proposer.call(import)
        import.update!(status: "ready")
      end
    end

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
