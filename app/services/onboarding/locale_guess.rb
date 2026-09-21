# frozen_string_literal: true

# Best guess of where a new user lives, so onboarding never has to ask: the country picked
# on the landing page, else Cloudflare's IP country, else the browser's time zone.
class Onboarding::LocaleGuess
  CLOUDFLARE_HEADER = "CF-IPCountry"

  # Browsers still report per-country zone names that tzdata folds into Abidjan and Lagos.
  AFRICAN_ZONES = {
    "Africa/Abidjan" => "CI", "Africa/Lagos" => "NG", "Africa/Porto-Novo" => "BJ", "Africa/Dakar" => "SN",
    "Africa/Lome" => "TG", "Africa/Ouagadougou" => "BF", "Africa/Bamako" => "ML", "Africa/Niamey" => "NE",
    "Africa/Conakry" => "GN", "Africa/Accra" => "GH", "Africa/Douala" => "CM", "Africa/Libreville" => "GA",
    "Africa/Brazzaville" => "CG", "Africa/Kinshasa" => "CD", "Africa/Bangui" => "CF", "Africa/Malabo" => "GQ"
  }.freeze

  attr_reader :country, :currency

  def initialize(request:, picked_country: nil, picked_currency: nil, time_zone: nil)
    @country = [ picked_country, request.headers[CLOUDFLARE_HEADER], country_of(time_zone) ]
               .filter_map { |code| ISO3166::Country[code.to_s.upcase]&.alpha2 }.first
    @currency = [ picked_currency, (ISO3166::Country[@country].currency_code if @country) ]
                .find { |code| Space::CURRENCIES.include?(code) }
  end

  private

  # Beyond the known African zones, only a zone that belongs to a single country says anything.
  def country_of(time_zone)
    return if time_zone.blank?
    return AFRICAN_ZONES[time_zone] if AFRICAN_ZONES.key?(time_zone)

    codes = TZInfo::Country.all.select { |c| c.zone_identifiers.include?(time_zone) }.map(&:code)
    codes.first if codes.one?
  end
end
