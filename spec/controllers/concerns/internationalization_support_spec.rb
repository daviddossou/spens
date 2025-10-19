# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternationalizationSupport, type: :controller do
  include Devise::Test::ControllerHelpers

  it_behaves_like 'a controller concern', InternationalizationSupport
  it_behaves_like 'a concern with before_actions', InternationalizationSupport, [:set_locale]

  controller(ApplicationController) do
    include InternationalizationSupport
    # Skip other concerns that interfere with testing
    skip_before_action :redirect_to_onboarding, if: -> { true }
    skip_before_action :configure_permitted_parameters, if: -> { true }

    def index
      render json: { locale: I18n.locale.to_s }
    end
  end

  before do
    # Store and set up test environment
    @original_available_locales = I18n.available_locales
    I18n.available_locales = [:en, :es, :fr]
    I18n.locale = I18n.default_locale
    session.clear
  end

  after do
    # Restore original state
    I18n.available_locales = @original_available_locales
    I18n.locale = I18n.default_locale
  end

  describe '#set_locale' do
    context 'when locale is provided in params' do
      it 'sets the locale from params' do
        get :index, params: { locale: 'es' }

        expect(I18n.locale).to eq(:es)
        expect(session[:locale]).to eq("es")
        expect(JSON.parse(response.body)['locale']).to eq('es')
      end

      it 'falls back to default locale for invalid param locale' do
        get :index, params: { locale: 'invalid' }

        expect(I18n.locale).to eq(I18n.default_locale)
        expect(session[:locale]).to eq(I18n.default_locale)
      end
    end

    context 'when locale is provided in session' do
      it 'sets the locale from session when params locale is not present' do
        session[:locale] = :fr
        get :index

        expect(I18n.locale).to eq(:fr)
        expect(session[:locale]).to eq(:fr)
        expect(JSON.parse(response.body)['locale']).to eq('fr')
      end

      it 'prefers params locale over session locale' do
        session[:locale] = :fr
        get :index, params: { locale: 'es' }

        expect(I18n.locale).to eq(:es)
        expect(session[:locale]).to eq("es")
        expect(JSON.parse(response.body)['locale']).to eq('es')
      end
    end

    context 'when locale is extracted from Accept-Language header' do
      it 'sets locale from Accept-Language header when no params or session locale' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-FR,fr;q=0.9,en;q=0.8'
        get :index

        expect(I18n.locale).to eq(:fr)
        expect(session[:locale]).to eq("fr")
      end

      it 'falls back to default locale for unsupported Accept-Language header' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'zh-CN,zh;q=0.9'
        get :index

        expect(I18n.locale).to eq(I18n.default_locale)
        expect(session[:locale]).to eq(I18n.default_locale)
      end

      it 'handles malformed Accept-Language header gracefully' do
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'invalid-header'
        get :index

        expect(I18n.locale).to eq(I18n.default_locale)
        expect(session[:locale]).to eq(I18n.default_locale)
      end

      it 'handles missing Accept-Language header' do
        request.env.delete('HTTP_ACCEPT_LANGUAGE')
        get :index

        expect(I18n.locale).to eq(I18n.default_locale)
        expect(session[:locale]).to eq(I18n.default_locale)
      end
    end

    context 'when no locale source is available' do
      it 'falls back to default locale' do
        get :index

        expect(I18n.locale).to eq(I18n.default_locale)
        expect(session[:locale]).to eq(I18n.default_locale)
      end
    end

    context 'locale precedence' do
      it 'follows correct precedence: params > session > header > default' do
        session[:locale] = :fr
        request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE,de;q=0.9'

        get :index
        expect(I18n.locale).to eq(:fr)

        get :index, params: { locale: 'es' }
        expect(I18n.locale).to eq(:es)
      end
    end
  end

  describe '#extract_locale_from_accept_language_header' do
    it 'extracts first two-letter language code' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'en-US,en;q=0.9,es;q=0.8'

      extracted = controller.send(:extract_locale_from_accept_language_header)
      expect(extracted).to eq('en')
    end

    it 'returns nil when header is not present' do
      request.env.delete('HTTP_ACCEPT_LANGUAGE')

      extracted = controller.send(:extract_locale_from_accept_language_header)
      expect(extracted).to be_nil
    end

    it 'returns nil when header format is invalid' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = '123invalid'  # Doesn't start with two letters

      extracted = controller.send(:extract_locale_from_accept_language_header)
      expect(extracted).to be_nil
    end

    it 'handles complex Accept-Language headers' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7'

      extracted = controller.send(:extract_locale_from_accept_language_header)
      expect(extracted).to eq('fr')
    end
  end

  describe 'integration with I18n' do
    it 'properly validates locales against available locales' do
      get :index, params: { locale: 'es' }
      expect(I18n.locale).to eq(:es)

      get :index, params: { locale: 'de' }  # Not in available_locales
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end
end
