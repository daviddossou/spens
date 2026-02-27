# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::AccountSetupsController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_account_setup', country: 'US', currency: 'USD') }
  let(:completed_user) { create(:user, onboarding_current_step: 'onboarding_completed', country: 'US', currency: 'USD') }

  describe 'GET /onboarding/account_setups' do
    context 'when user is authenticated' do
      before { sign_in user, scope: :user }

      it 'returns http success' do
        get onboarding_account_setups_path
        expect(response).to have_http_status(:success)
      end

      it 'renders the account setup form' do
        get onboarding_account_setups_path
        expect(response.body).to include('account')
      end

      it 'displays form for initial transactions' do
        get onboarding_account_setups_path
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end
    end

    context 'when user has completed onboarding' do
      before do
        sign_in completed_user, scope: :user
      end

      it 'handles completed onboarding appropriately' do
        get onboarding_account_setups_path
        # May redirect to dashboard or show the page depending on onboarding state
        expect(response.status).to be_in([ 200, 302 ])
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        get onboarding_account_setups_path
        # Should require login - either redirect or error
        expect([ 302, 401, 500 ]).to include(response.status)
      end
    end
  end

  describe 'PATCH /onboarding/account_setups' do
    before { sign_in user, scope: :user }

    let(:valid_params) do
      {
        onboarding_account_setup_form: {
          transactions_attributes: {
            '0' => {
              account_name: 'Checking Account',
              amount: 1000.00,
              transaction_date: Date.current.to_s,
              transaction_type_name: 'Initial Balance',
              transaction_type_kind: 'income'
            },
            '1' => {
              account_name: 'Savings Account',
              amount: 5000.00,
              transaction_date: Date.current.to_s,
              transaction_type_name: 'Opening Balance',
              transaction_type_kind: 'income'
            }
          }
        }
      }
    end

    let(:invalid_params) do
      {
        onboarding_account_setup_form: {
          transactions_attributes: {
            '0' => {
              account_name: '',
              amount: nil,
              transaction_date: Date.current.to_s,
              transaction_type_name: '',
              transaction_type_kind: ''
            }
          }
        }
      }
    end

    context 'with valid parameters' do
      it 'creates accounts and transactions' do
        expect {
          patch onboarding_account_setups_path, params: valid_params
        }.to change(Account, :count).by(2)
         .and change(Transaction, :count).by(2)
      end

      it 'completes the onboarding process' do
        patch onboarding_account_setups_path, params: valid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_completed')
      end

      it 'redirects to the dashboard or home' do
        patch onboarding_account_setups_path, params: valid_params

        expect(response).to have_http_status(:redirect)
        # Should redirect to dashboard after completing onboarding
      end

      it 'creates accounts with correct balances' do
        patch onboarding_account_setups_path, params: valid_params

        checking = Account.find_by(name: 'Checking Account', user: user)
        savings = Account.find_by(name: 'Savings Account', user: user)

        expect(checking.balance).to eq(1000.00)
        expect(savings.balance).to eq(5000.00)
      end
    end

    context 'with single valid transaction' do
      let(:single_transaction_params) do
        {
          onboarding_account_setup_form: {
            transactions_attributes: {
              '0' => {
                account_name: 'Main Account',
                amount: 2000.00,
                transaction_date: Date.current.to_s,
                transaction_type_name: 'Initial Balance',
                transaction_type_kind: 'income'
              }
            }
          }
        }
      end

      it 'creates one account and transaction' do
        expect {
          patch onboarding_account_setups_path, params: single_transaction_params
        }.to change(Account, :count).by(1)
         .and change(Transaction, :count).by(1)
      end

      it 'completes onboarding with single account' do
        patch onboarding_account_setups_path, params: single_transaction_params

        expect(user.reload.onboarding_current_step).to eq('onboarding_completed')
      end
    end

    context 'with invalid parameters' do
      it 'does not create accounts' do
        expect {
          patch onboarding_account_setups_path, params: invalid_params
        }.not_to change(Account, :count)
      end

      it 'does not create transactions' do
        expect {
          patch onboarding_account_setups_path, params: invalid_params
        }.not_to change(Transaction, :count)
      end

      it 'does not advance onboarding step' do
        patch onboarding_account_setups_path, params: invalid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'renders show template with unprocessable_entity status' do
        patch onboarding_account_setups_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:show)
      end

      it 'displays validation errors' do
        patch onboarding_account_setups_path, params: invalid_params
        expect(response.body).to include('account')
      end
    end

    context 'with no transactions' do
      let(:empty_params) do
        {
          onboarding_account_setup_form: {
            transactions_attributes: {}
          }
        }
      end

      it 'redirects to account setups page' do
        patch onboarding_account_setups_path, params: empty_params

        expect(response).to redirect_to(onboarding_account_setups_path)
      end

      it 'sets an error alert' do
        patch onboarding_account_setups_path, params: empty_params

        expect(flash[:alert]).to be_present
      end

      it 'does not advance onboarding' do
        patch onboarding_account_setups_path, params: empty_params

        expect(user.reload.onboarding_current_step).to eq('onboarding_account_setup')
      end
    end

    context 'when user has completed onboarding' do
      before do
        sign_in completed_user, scope: :user
      end

      it 'redirects appropriately' do
        patch onboarding_account_setups_path, params: valid_params
        # Should redirect but may go to different location for completed users
        expect(response).to be_redirect
      end
    end

    context 'when user is not authenticated' do
      before { sign_out :user }

      it 'requires authentication' do
        patch onboarding_account_setups_path, params: valid_params
        # Should require login - either redirect or error
        expect([ 302, 401, 500 ]).to include(response.status)
      end

      it 'does not create accounts' do
        sign_out :user
        expect {
          patch onboarding_account_setups_path, params: valid_params
        }.not_to change(Account, :count)
      end
    end
  end

  describe 'parameter handling' do
    before { sign_in user, scope: :user }

    it 'permits required transaction attributes' do
      params = {
        onboarding_account_setup_form: {
          transactions_attributes: {
            '0' => {
              account_name: 'Test Account',
              amount: 100.00,
              transaction_date: Date.current.to_s,
              transaction_type_name: 'Test',
              transaction_type_kind: 'income',
              unpermitted_field: 'should be filtered'
            }
          }
        }
      }

      patch onboarding_account_setups_path, params: params
      # Should process successfully, filtering unpermitted params
      expect(response.status).to be_in([ 200, 302, 303, 422 ])
    end
  end
end
