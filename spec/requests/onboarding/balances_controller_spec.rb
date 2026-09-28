# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::BalancesController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_balances', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }
  let(:copy) { ->(key, **options) { CGI.escapeHTML(I18n.t("onboarding.balances.show.#{key}", **options)) } }
  let(:wallet) { I18n.t('account_templates.wallet') }
  let(:momo) { I18n.t('account_templates.mobile_money') }
  let(:fcfa) { ->(amount) { ApplicationController.helpers.money(amount, 'XOF') } }

  before { travel_to Time.utc(2026, 9, 22, 12) }

  def note_expense(amount, category, account)
    post transactions_path, params: { transaction: { kind: 'expense', amount: amount, transaction_type_name: category,
                                                     account_name: account, transaction_date: Date.current } }
  end

  def account(name)
    space.accounts.find_by!(name: name)
  end

  context 'when signed in' do
    before do
      sign_in user, scope: :user
      note_expense('2000', 'Riz du marché', wallet)
      note_expense('1500', 'Zem', momo)
    end

    it 'shows one entry per account, what it spent, and the places not used yet' do
      get onboarding_balances_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('onboarding.step_header_component.step', step: 3, total: 3))
      expect(response.body).to include(copy.call(:spent_today, amount: fcfa.call(2000)), copy.call(:spent_today, amount: fcfa.call(1500)),
                                       "balances[balances][#{account(wallet).id}]", copy.call(:maybe_also))
      expect(response.body).to include(CGI.escapeHTML(I18n.t('account_templates.bank')))
      expect(response.body).not_to include("data-name=\"#{CGI.escapeHTML(wallet)}\"")
    end

    it 'writes the opening balances so the entered figure is what each account holds now' do
      allow(Analytics).to receive(:track)

      patch onboarding_balances_path, params: { balances: { balances: { account(wallet).id => '8 500', account(momo).id => '12000' } } }

      expect(response).to redirect_to(onboarding_summaries_path)
      expect(space.reload).to be_onboarding_summary
      expect(account(wallet).reload.balance).to eq(8500)
      expect(account(momo).reload.balance).to eq(12_000)
      opening = space.transactions.joins(:transaction_type).where(transaction_types: { kind: 'initial_balance' })
      expect(opening.sum(:amount)).to eq(10_500 + 13_500)
      expect(Analytics).to have_received(:track).with(user, 'onboarding_completed', hash_including(accounts: 2, extra_accounts: 0, expenses: 2))
    end

    it 'creates the extra places with their balance and drops a blank one' do
      patch onboarding_balances_path, params: { balances: {
        balances: { account(wallet).id => '8500', account(momo).id => '12000' },
        extra: [ { name: I18n.t('account_templates.bank'), amount: '50 000' }, { name: I18n.t('account_templates.cash_box'), amount: '' } ]
      } }

      expect(response).to redirect_to(onboarding_summaries_path)
      expect(space.accounts.count).to eq(3)
      expect(account(I18n.t('account_templates.bank')).balance).to eq(50_000)
    end

    it 'refuses a missing balance and names the account' do
      patch onboarding_balances_path, params: { balances: { balances: { account(wallet).id => '8500' } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(CGI.escapeHTML(I18n.t('onboarding.balances.errors.missing', account: momo)))
      expect(space.reload).to be_onboarding_balances
      expect(account(wallet).reload.balance).to eq(-2000)
    end

    it 'keeps the rest of the app behind onboarding' do
      get dashboard_path

      expect(response).to redirect_to(onboarding_path)
    end
  end
end
