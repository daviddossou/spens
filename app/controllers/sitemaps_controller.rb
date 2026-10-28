# frozen_string_literal: true

# sitemap.xml: the indexable public pages, each with its language alternates.
class SitemapsController < ApplicationController
  PAGES = %i[landing download guide privacy terms].freeze
  # Pages that exist in one language only: one unprefixed URL, no alternates.
  SINGLE_LANGUAGE_PAGES = %i[cohort].freeze
  seo_indexable :show

  def show
    @pages = PAGES
    @single_language_pages = SINGLE_LANGUAGE_PAGES
    expires_in 1.day, public: true
  end
end
