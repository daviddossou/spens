# frozen_string_literal: true

module Navigation
  # A contextual top bar for detail pages: a back chevron on the left, the record's
  # name centered over an optional subtitle, and an optional action slot on the
  # right (e.g. a ⋯ menu). Pages opt in via `content_for(:header)`, replacing the
  # global app header.
  class DetailHeaderComponent < ViewComponent::Base
    renders_one :action

    attr_reader :back_url, :title, :back_label, :subtitle

    def initialize(back_url:, title:, back_label: nil, subtitle: nil)
      @back_url = back_url
      @title = title
      @back_label = back_label
      @subtitle = subtitle
    end
  end
end
