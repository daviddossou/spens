# frozen_string_literal: true

# A minimal valid PDF with `pages` blank pages, for specs that count pages.
module PdfFixture
  def blank_pdf(pages)
    kids = (0...pages).map { |i| "#{i + 3} 0 R" }.join(" ")
    objects = [ "<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Kids [#{kids}] /Count #{pages} >>" ]
    pages.times { objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>" }

    pdf = +"%PDF-1.4\n"
    offsets = objects.each_with_index.map do |body, i|
      offset = pdf.bytesize
      pdf << "#{i + 1} 0 obj\n#{body}\nendobj\n"
      offset
    end
    xref = pdf.bytesize
    pdf << "xref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
    offsets.each { |o| pdf << format("%010d 00000 n \n", o) }
    pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref}\n%%EOF\n"
  end

  def pdf_upload(pages, name: "statement.pdf")
    file = Tempfile.new([ "statement", ".pdf" ]).tap { |f| f.binmode.write(blank_pdf(pages)) && f.rewind }
    Rack::Test::UploadedFile.new(file.path, "application/pdf", original_filename: name)
  end

  def image_upload
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/capture.png"), "image/png")
  end
end

RSpec.configure { |config| config.include PdfFixture }
