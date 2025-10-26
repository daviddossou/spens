# frozen_string_literal: true

class Forms::SelectFieldComponentPreview < ViewComponent::Preview
  # Enable form helpers in previews
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  # Default select field
  # @param field_name text
  def default(field_name: "country")
    render_with_template locals: {
      field_name: field_name.to_sym,
      country_options: country_options
    }
  end

  # Required field with blank option
  def required_field
    render_with_template locals: { currencies: currency_options }
  end

  # With custom styling
  def custom_styling
    render_with_template locals: { sizes: [ 'Small', 'Medium', 'Large', 'X-Large' ] }
  end

  # Different option formats
  def option_formats
    render_with_template
  end

  # Multiple select fields
  def multiple_fields
    render_with_template
  end

  # Searchable select (for large option lists)
  def searchable
    render_with_template locals: { countries: all_countries }
  end

  # Select with priority options
  def with_priority_options
    render_with_template locals: {
      countries: country_options,
      priority: priority_countries
    }
  end

  # Searchable with priority options
  def searchable_with_priorities
    render_with_template locals: {
      countries: all_countries,
      priority: priority_countries
    }
  end

  # Searchable with blank option (no placeholder text)
  def searchable_with_blank
    render_with_template locals: { countries: all_countries }
  end

  # Field with errors
  def with_errors
    user = User.new
    user.errors.add(:country, "can't be blank")
    user.errors.add(:country, "is invalid")

    render_with_template locals: { user: user }
  end

  private

  def country_options
    {
      'BF' => 'Burkina Faso',
      'CI' => "Côte d'Ivoire",
      'SN' => 'Senegal',
      'ML' => 'Mali',
      'NE' => 'Niger',
      'TG' => 'Togo',
      'BJ' => 'Benin',
      'GN' => 'Guinea',
      'CM' => 'Cameroon',
      'CD' => 'Democratic Republic of Congo',
      'FR' => 'France',
      'CA' => 'Canada'
    }
  end

  def currency_options
    {
      'XOF' => 'West African CFA Franc (XOF)',
      'XAF' => 'Central African CFA Franc (XAF)',
      'EUR' => 'Euro (EUR)',
      'USD' => 'US Dollar (USD)',
      'GBP' => 'British Pound (GBP)',
      'CAD' => 'Canadian Dollar (CAD)'
    }
  end

  def sample_options
    [ 'Option 1', 'Option 2', 'Option 3' ]
  end

  def priority_countries
    {
      'BF' => 'Burkina Faso',
      'CI' => "Côte d'Ivoire",
      'SN' => 'Senegal',
      'ML' => 'Mali'
    }
  end

  def all_countries
    # Simplified list - in real app would use countries gem
    {
      'AF' => 'Afghanistan',
      'AL' => 'Albania',
      'DZ' => 'Algeria',
      'AR' => 'Argentina',
      'AU' => 'Australia',
      'AT' => 'Austria',
      'BH' => 'Bahrain',
      'BD' => 'Bangladesh',
      'BE' => 'Belgium',
      'BF' => 'Burkina Faso',
      'CM' => 'Cameroon',
      'CA' => 'Canada',
      'CL' => 'Chile',
      'CN' => 'China',
      'CI' => "Côte d'Ivoire",
      'CD' => 'Democratic Republic of Congo',
      'DK' => 'Denmark',
      'EG' => 'Egypt',
      'FR' => 'France',
      'DE' => 'Germany',
      'GH' => 'Ghana',
      'GR' => 'Greece',
      'IN' => 'India',
      'ID' => 'Indonesia',
      'IE' => 'Ireland',
      'IL' => 'Israel',
      'IT' => 'Italy',
      'JP' => 'Japan',
      'KE' => 'Kenya',
      'ML' => 'Mali',
      'MX' => 'Mexico',
      'MA' => 'Morocco',
      'NL' => 'Netherlands',
      'NZ' => 'New Zealand',
      'NE' => 'Niger',
      'NG' => 'Nigeria',
      'NO' => 'Norway',
      'PK' => 'Pakistan',
      'PL' => 'Poland',
      'PT' => 'Portugal',
      'RO' => 'Romania',
      'RU' => 'Russia',
      'SA' => 'Saudi Arabia',
      'SN' => 'Senegal',
      'SG' => 'Singapore',
      'ZA' => 'South Africa',
      'KR' => 'South Korea',
      'ES' => 'Spain',
      'SE' => 'Sweden',
      'CH' => 'Switzerland',
      'TG' => 'Togo',
      'TR' => 'Turkey',
      'AE' => 'United Arab Emirates',
      'GB' => 'United Kingdom',
      'US' => 'United States',
      'VN' => 'Vietnam'
    }
  end
end
