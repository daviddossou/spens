# frozen_string_literal: true

module StatementImports
  # Turns uploaded files into capture blobs within the import's budget of 5 slots: an image takes
  # one, a PDF one per page (a page holds about as many lines as a screenshot, and one read must
  # stay short). Files beyond the budget are left out, like the 6th screenshot of a gallery pick.
  class AddCaptures
    Result = Data.define(:blobs, :problem, :pages, :room)

    def self.call(files, room:)
      new(files, room).call
    end

    def initialize(files, room)
      @files = Array(files).select { _1.respond_to?(:original_filename) }
      @room = room
    end

    def call
      blobs = []
      @files.each do |file|
        return result(blobs, :unreadable) unless StatementImport.acceptable?(file)

        pages = page_count(file) or return result(blobs, :unreadable)
        break if @room.zero?
        return result(blobs, :pdf_too_long, pages: pages) if pages > @room

        blobs << ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename,
                                                        content_type: file.content_type, metadata: { "pages" => pages })
        @room -= pages
      end
      result(blobs, nil)
    end

    private

    def result(blobs, problem, pages: nil)
      Result.new(blobs: blobs, problem: problem, pages: pages, room: @room)
    end

    def page_count(file)
      return 1 unless Marcel::MimeType.for(file, name: file.original_filename) == "application/pdf"

      PDF::Reader.new(file.tempfile.path).page_count.then { _1.positive? ? _1 : nil }
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError, PDF::Reader::EncryptedPDFError
      nil
    ensure
      file.rewind if file.respond_to?(:rewind)
    end
  end
end
