# frozen_string_literal: true

require "csv"

# Read-only export of the feedback-email segments (see the September 2026 campaign brief).
# Writes three CSVs (A: nothing entered, B: started then left, C: active) to a local
# directory, never into the repo. No writes, no e-mail.
#
#   bin/rails segments:feedback
#   CUTOFF=2026-09-26 DORMANT_DAYS=14 OUT=tmp/segments EXCLUDE=me@x.com,other@y.com bin/rails segments:feedback
namespace :segments do
  desc "Export feedback e-mail segments (A/B/C) as CSV, read-only"
  task feedback: :environment do
    cutoff = Date.parse(ENV.fetch("CUTOFF", "2026-09-26"))
    dormant_days = Integer(ENV.fetch("DORMANT_DAYS", "14"))
    out_dir = Pathname(ENV.fetch("OUT", Rails.root.join("tmp/segments").to_s))
    excluded_emails = %w[dossoudavid00@gmail.com] + ENV.fetch("EXCLUDE", "").split(",").map(&:strip).reject(&:blank?)

    exporter = Segments::FeedbackExporter.new(
      cutoff: cutoff, dormant_days: dormant_days, excluded_emails: excluded_emails
    )
    result = exporter.call

    FileUtils.mkdir_p(out_dir)
    result.segments.each do |key, rows|
      path = out_dir.join("segment_#{key}.csv")
      CSV.open(path, "w") do |csv|
        csv << Segments::FeedbackExporter::COLUMNS
        rows.each { |row| csv << row.values_at(*Segments::FeedbackExporter::COLUMNS) }
      end
      puts "#{path}: #{rows.size} rows"
    end

    puts
    puts result.report
  end
end
