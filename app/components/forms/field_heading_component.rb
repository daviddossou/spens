# frozen_string_literal: true

class Forms::FieldHeadingComponent < ViewComponent::Base
  renders_one :label
  renders_one :hint
end
