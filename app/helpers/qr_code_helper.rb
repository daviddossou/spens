# frozen_string_literal: true

module QrCodeHelper
  # Inline SVG, so the code stays crisp and needs no image request.
  def qr_code_svg(text, label:)
    svg = RQRCode::QRCode.new(text).as_svg(module_size: 4, standalone: true, use_path: true, viewbox: true, svg_attributes: { role: "img", "aria-label": label })
    svg.html_safe
  end
end
