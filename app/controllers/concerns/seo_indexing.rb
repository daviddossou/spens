# frozen_string_literal: true

# Search engines only get the pages a controller opts in with `seo_indexable`; everything
# else (the app, auth, redirects) answers "X-Robots-Tag: noindex" and carries the meta tag.
module SeoIndexing
  extend ActiveSupport::Concern

  included do
    class_attribute :seo_indexable_actions, default: []
    helper_method :seo_indexable?
    before_action :set_robots_header
  end

  class_methods do
    def seo_indexable(*actions)
      self.seo_indexable_actions = actions.map(&:to_s)
    end
  end

  private

  def seo_indexable?
    seo_indexable_actions.include?(action_name)
  end

  def set_robots_header
    response.headers["X-Robots-Tag"] = "noindex" unless seo_indexable?
  end
end
