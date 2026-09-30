# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::FirstDaysController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_first_day', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }
  let(:copy) { ->(key, **options) { CGI.escapeHTML(I18n.t("onboarding.first_days.show.#{key}", **options)) } }
  let(:wallet) { I18n.t('account_templates.wallet') }

  # Fixed noon: the controller reads "today" in the member's zone (UTC+1); around midnight
  # UTC the spec's Date.current and the controller's would name different days.
  before { travel_to Time.utc(2026, 9, 22, 12) }

  def note_expense(amount, category, account: wallet, date: Date.current)
    post transactions_path, params: { transaction: { kind: 'expense', amount: amount, transaction_type_name: category,
                                                     account_name: account, transaction_date: date } }
  end

  it 'requires authentication' do
    get onboarding_first_days_path

    expect(response).to have_http_status(:redirect)
  end

  context 'when signed in' do
    before { sign_in user, scope: :user }

    it 'opens as step 2 on the invitation to note an expense, with no way past' do
      get onboarding_first_days_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('onboarding.step_header_component.step', step: 2, total: 3))
      expect(response.body).to include(copy.call(:add_first), copy.call(:empty_title))
      expect(response.body).not_to include(copy.call(:continue))
      expect(response.body).to match(/<turbo-frame[^>]*id="modal"/)
    end

    it 'opens the real expense sheet, with the account chips, before onboarding is completed' do
      get new_transaction_path(kind: 'expense')

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('transactions.new.onboarding_subtitle'), 'data-controller="name-chips"',
                                       CGI.escapeHTML(I18n.t('transactions.form.cta_need_account')))
      expect(response.body).to include(CGI.escapeHTML(wallet), CGI.escapeHTML(I18n.t('account_templates.mobile_money')))
    end

    it 'refuses an expense without an account while onboarding' do
      post transactions_path, params: { transaction: { kind: 'expense', amount: '2000', transaction_type_name: 'Riz du marché' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(space.transactions.count).to eq(0)
    end

    it 'creates the account named in the sheet and comes back to the list, without a flash' do
      note_expense('2000', 'Riz du marché')

      expect(response).to redirect_to(onboarding_first_days_path)
      expect(flash[:notice]).to be_nil
      expect(space.accounts.pluck(:name)).to eq([ wallet ])

      get onboarding_first_days_path
      expect(response.body).to include('Riz du marché', copy.call(:expenses, count: 1), copy.call(:accounts, count: 1),
                                       copy.call(:continue))
    end

    it 'lists the expenses as real rows, without links, and congratulates' do
      note_expense('2000', 'Riz du marché')
      note_expense('700', 'Eau en sachet', account: I18n.t('account_templates.mobile_money'))

      get onboarding_first_days_path

      expect(response.body).to include(copy.call(:noted_today), copy.call(:congrats, count: 2), 'transaction-item--static',
                                       copy.call(:expenses, count: 2), copy.call(:accounts, count: 2), copy.call(:add_another))
      expect(response.body).not_to include('transaction-item__chevron')
    end

    it 'keeps an expense noted for yesterday, to try, on the list' do
      note_expense('500', 'Zem', date: Date.yesterday)

      get onboarding_first_days_path

      expect(response.body).to include('Zem', copy.call(:continue))
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

    it 'does not move on with nothing noted' do
      patch onboarding_first_days_path

      expect(response).to redirect_to(onboarding_first_days_path)
      expect(space.reload).to be_onboarding_first_day
    end

    it 'moves on to the balances once an expense exists' do
      allow(Analytics).to receive(:track)
      note_expense('2000', 'Riz du marché')

      patch onboarding_first_days_path

      expect(response).to redirect_to(onboarding_balances_path)
      expect(space.reload).to be_onboarding_balances
      expect(Analytics).to have_received(:track).with(user, 'onboarding_step_completed',
                                                      hash_including(step: 'first_day', expenses: 1, accounts: 1))
      expect(Analytics).not_to have_received(:track).with(user, 'onboarding_completed', anything)
    end
  end
end
