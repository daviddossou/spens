# frozen_string_literal: true

module Spaces
  # @label Learned mapping row
  class MappingRowComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # A phrase mapped to a category, with its retarget select
    def default
      mapping = LearnedAlias.new(id: SecureRandom.uuid, phrase: "zem", display_phrase: "Zem", taxonomy_key: "public_transport",
                                 space: preview_space, source: "user", state: "active")
      render with_helpers(Spaces::MappingRowComponent.new(space: preview_space, mapping: mapping))
    end

    # A phrase mapped to an operation kind: no select, just forget
    def keyword
      mapping = LearnedKeyword.new(id: SecureRandom.uuid, phrase: "depanne", display_phrase: "dépanné", kind: "debt_out",
                                   space: preview_space, source: "user", state: "active")
      render with_helpers(Spaces::MappingRowComponent.new(space: preview_space, mapping: mapping, keyword: true))
    end
  end
end
