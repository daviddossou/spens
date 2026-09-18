# frozen_string_literal: true

# sitemap.xml: the indexable public pages, each with its language alternates.
class SitemapsController < ApplicationController
  PAGES = %i[landing guide privacy terms].freeze
  seo_indexable :show

  def show
    @pages = PAGES
    expires_in 1.day, public: true
  end
end
