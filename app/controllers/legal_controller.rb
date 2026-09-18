class LegalController < ApplicationController
  layout "marketing"
  seo_indexable :privacy, :terms

  def privacy
  end

  def terms
  end
end
