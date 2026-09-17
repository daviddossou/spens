# frozen_string_literal: true

# A short status word set in a tinted pill. `classes` carries the BEM class the
# page already styles; `tone` maps to the generic badge palette.
class Ui::BadgeComponent < ViewComponent::Base
  TONES = %i[neutral success warning danger info].freeze

  def initialize(text = nil, tone: nil, classes: nil, **html_options)
    @text = text
    @tone = tone
    @classes = classes
    @html_options = html_options
  end

  def call
    tag.span(content.presence || @text, class: css_classes, **@html_options)
  end

  private

  def css_classes
    tone_class = "badge badge--#{TONES.include?(@tone) ? @tone : :neutral}" if @tone
    [ tone_class, @classes ].compact.join(" ").presence
  end
end
