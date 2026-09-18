# frozen_string_literal: true

module SeoHelper
  # One canonical origin whatever host served the page (www, the proxy's own name).
  def seo_origin
    Rails.application.config.x.canonical_origin.presence || request.base_url
  end

  # The current page in a given locale, without its query string (UTMs, guide_link).
  def seo_url(locale: I18n.locale)
    seo_origin + url_for(locale: locale, only_path: true)
  end

  # hreflang pairs; x-default is the unprefixed URL, which follows the visitor's language.
  def seo_alternates
    I18n.available_locales.to_h { |locale| [ locale.to_s, seo_url(locale: locale) ] }
      .merge("x-default" => seo_url(locale: nil))
  end

  def seo_image_url
    "#{seo_origin}/og-#{I18n.locale}.png"
  end

  # schema.org description of the product, for the landing's rich result.
  def seo_app_json_ld
    tag.script({
      "@context": "https://schema.org", "@type": "SoftwareApplication",
      name: "Spens", url: seo_url, image: seo_image_url, inLanguage: I18n.locale.to_s,
      description: t("landing.meta.description"),
      applicationCategory: "FinanceApplication", operatingSystem: "Web, Android",
      offers: { "@type": "Offer", price: "0", priceCurrency: "XOF" }
    }.to_json.html_safe, type: "application/ld+json")
  end
end
