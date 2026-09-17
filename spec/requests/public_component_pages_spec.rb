# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public component pages", type: :request do
  include Devise::Test::IntegrationHelpers
  %w[fr en].each do |locale|
    [ "welcome", "guide", "guide/thanks" ].each do |page|
      it "renders #{page} in #{locale} with its navigation and no missing translations" do
        get "/#{locale}/#{page}"
        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)
        expect(html.at_css(".landing-nav__brand")).to be_present
        expect(html.css(".translation_missing")).to be_empty
        if page == "welcome"
          expect(html.css('[data-controller="landing--calculator"] input')).not_to be_empty
          expect(html.css('[data-landing--features-target="card"]')).not_to be_empty
        elsif page == "guide"
          expect(html.css('a[download][data-landing--meta-events-placement-param]').length).to eq(2)
        end
      end
    end
  end

  it "renders the invitation form and its unscoped email field" do
    user = create(:user)
    sign_in user
    get new_space_member_path(space_id: user.spaces.first.id)
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('input[name="email"]')).to be_present
  end
end
