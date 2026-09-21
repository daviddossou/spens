# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::FirstDaysController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_first_day', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }
  let(:copy) { ->(key, **options) { CGI.escapeHTML(I18n.t("onboarding.first_days.show.#{key}", **options)) } }

  def note_expense(amount, category)
    post transactions_path, params: { transaction: { kind: 'expense', amount: amount, transaction_type_name: category,
                                                     transaction_date: Date.current } }
  end

  it 'requires authentication' do
    get onboarding_first_days_path

    expect(response).to have_http_status(:redirect)
  end

  context 'when signed in' do
    before { sign_in user, scope: :user }

    it 'opens on the invitation to note a first expense, with a way to skip' do
      get onboarding_first_days_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('onboarding.step_header_component.step', step: 3, total: 3))
      expect(response.body).to include(copy.call(:add_first), copy.call(:skip))
      expect(response.body).to match(/<turbo-frame[^>]*id="modal"/)
    end

    it 'opens the real expense sheet before onboarding is completed' do
      get new_transaction_path(kind: 'expense')

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('transactions.new.onboarding_subtitle'))
    end

    it 'comes back to the list after an expense, without a flash' do
      note_expense('2000', 'Riz du marché')

      expect(response).to redirect_to(onboarding_first_days_path)
      expect(flash[:notice]).to be_nil

      get onboarding_first_days_path
      expect(response.body).to include('Riz du marché', copy.call(:expenses, count: 1), copy.call(:done_for_today))
    end

    it 'lists a first expense as the real row, without a link, and congratulates' do
      note_expense('2000', 'Riz du marché')

      get onboarding_first_days_path

      expect(response.body).to include(copy.call(:noted_today), copy.call(:congrats, count: 1), 'transaction-item--static')
      expect(response.body).not_to include('transaction-item__chevron', 'analyses-stack')
    end

    it 'stays a list while every expense shares one category' do
      2.times { note_expense('500', 'Riz du marché') }

      get onboarding_first_days_path

      expect(response.body).to include(copy.call(:expenses, count: 2), 'transaction-item--static')
    end

    it 'replaces the list with the split of the day from two categories up, biggest first' do
      note_expense('700', 'Eau en sachet')
      note_expense('2000', 'Riz du marché')

      get onboarding_first_days_path

      expect(response.body).to include(copy.call(:mostly, category: 'riz du marché'), copy.call(:congrats, count: 2),
                                       'analyses-stack', copy.call(:add_another), copy.call(:done_for_today))
      expect(response.body).not_to include('transaction-item--static')
      expect(response.body.index('Riz du marché')).to be < response.body.index('Eau en sachet')
    end

    it 'offers the evening reminder once an expense is noted, and remembers the answer' do
      note_expense('2000', 'Riz du marché')

      get onboarding_first_days_path
      expect(response.body).to include('id="reminder_card"', CGI.escapeHTML(I18n.t('reminders.card.decline')))

      user.memberships.first.decline_reminder!
      get onboarding_first_days_path
      expect(response.body).to include(CGI.escapeHTML(I18n.t('reminders.card.declined')))
    end

    it 'keeps the rest of the app behind onboarding' do
      get dashboard_path

      expect(response).to redirect_to(onboarding_path)
    end

    it 'completes onboarding and lands on the dashboard, even with nothing spent' do
      allow(Analytics).to receive(:track)

      patch onboarding_first_days_path

      expect(response).to redirect_to(dashboard_path)
      expect(space.reload).to be_onboarding_completed
      expect(Analytics).to have_received(:track).with(user, 'onboarding_completed', hash_including(expenses: 0, skipped: true))
    end
  end
end
