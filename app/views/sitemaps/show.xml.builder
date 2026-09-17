# frozen_string_literal: true

origin = seo_origin
url_in = ->(page, locale) { origin + public_send("#{page}_path", locale: locale) }

xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9", "xmlns:xhtml": "http://www.w3.org/1999/xhtml" do
  @pages.each do |page|
    I18n.available_locales.each do |locale|
      xml.url do
        xml.loc url_in.(page, locale)
        I18n.available_locales.each do |alternate|
          xml.tag! "xhtml:link", rel: "alternate", hreflang: alternate, href: url_in.(page, alternate)
        end
        xml.tag! "xhtml:link", rel: "alternate", hreflang: "x-default", href: url_in.(page, nil)
      end
    end
  end
end
