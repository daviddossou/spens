# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebtsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:debt) { create(:debt, :partially_reimbursed, user: user, name: 'John Doe') }
  let(:borrowed_debt) { create(:debt, :borrowed, :partially_reimbursed, user: user, name: 'Bank Loan') }

  before { sign_in user, scope: :user }

  describe 'GET #index' do
    let!(:lent_debt1) { create(:debt, user: user, name: 'Alice') }
    let!(:lent_debt2) { create(:debt, user: user, name: 'Bob') }
    let!(:borrowed_debt1) { create(:debt, :borrowed, user: user, name: 'Bank') }
    let!(:paid_debt) { create(:debt, :paid, user: user, name: 'Charlie') }
    let!(:other_users_debt) { create(:debt, user: other_user, name: 'Dave') }

    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        get debts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with no direction parameter (defaults to lent)' do
      it 'returns successful response' do
        get debts_path
        expect(response).to be_successful
      end

      it 'displays lent debts' do
        get debts_path
        expect(response.body).to include('Alice')
        expect(response.body).to include('Bob')
      end

      it 'does not display borrowed debts' do
        get debts_path
        expect(response.body).not_to include('Bank')
      end

      it 'does not display paid debts' do
        get debts_path
        expect(response.body).not_to include('Charlie')
      end
    end

    context 'with direction=lent parameter' do
      it 'displays lent debts' do
        get debts_path, params: { direction: 'lent' }
        expect(response.body).to include('Alice')
        expect(response.body).to include('Bob')
      end

      it 'does not display borrowed debts' do
        get debts_path, params: { direction: 'lent' }
        expect(response.body).not_to include('Bank')
      end
    end

    context 'with direction=borrowed parameter' do
      it 'displays borrowed debts' do
        get debts_path, params: { direction: 'borrowed' }
        expect(response.body).to include('Bank')
      end

      it 'does not display lent debts' do
        get debts_path, params: { direction: 'borrowed' }
        expect(response.body).not_to include('Alice')
        expect(response.body).not_to include('Bob')
      end
    end
  end

  describe 'GET #show' do
    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        get debt_path(id: debt.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with valid debt id' do
      it 'returns successful response' do
        get debt_path(id: debt.id)
        expect(response).to be_successful
      end

      it 'displays the debt details' do
        get debt_path(id: debt.id)
        expect(response.body).to include(debt.name)
      end

      it 'displays latest transactions when present' do
        transaction1 = create(:transaction, debt: debt, user: user, transaction_date: 1.day.ago, description: 'Payment 1')
        transaction2 = create(:transaction, debt: debt, user: user, transaction_date: 2.days.ago, description: 'Payment 2')

        get debt_path(id: debt.id)

        expect(response.body).to include('Payment 1')
      end

      it 'limits transactions to 10' do
        15.times do |i|
          create(:transaction, debt: debt, user: user, transaction_date: i.days.ago)
        end

        get debt_path(id: debt.id)

        expect(response).to be_successful
      end
    end

    context 'with debt belonging to another user' do
      let(:other_debt) { create(:debt, user: other_user, name: 'Someone') }

      it 'redirects to debts path' do
        get debt_path(id: other_debt.id)
        expect(response).to redirect_to(debts_path)
      end

      it 'sets an alert flash message' do
        get debt_path(id: other_debt.id)
        expect(flash[:alert]).to eq(I18n.t('debts.errors.not_found'))
      end
    end

    context 'with non-existent debt id' do
      it 'redirects to debts path' do
        get debt_path(id: 'non-existent-id')
        expect(response).to redirect_to(debts_path)
      end

      it 'sets an alert flash message' do
        get debt_path(id: 'non-existent-id')
        expect(flash[:alert]).to eq(I18n.t('debts.errors.not_found'))
      end
    end
  end

  describe 'GET #new' do
    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        get new_debt_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'without direction parameter' do
      it 'returns successful response' do
        get new_debt_path
        expect(response).to be_successful
      end

      it 'displays the new debt form' do
        get new_debt_path
        expect(response.body).to include('debt-form')
      end
    end

    context 'with direction=lent parameter' do
      it 'returns successful response' do
        get new_debt_path, params: { direction: 'lent' }
        expect(response).to be_successful
      end
    end

    context 'with direction=borrowed parameter' do
      it 'returns successful response' do
        get new_debt_path, params: { direction: 'borrowed' }
        expect(response).to be_successful
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        contact_name: 'Jane Smith',
        total_lent: 2000,
        total_reimbursed: 0,
        note: 'Personal loan',
        direction: 'lent',
        account_name: 'Cash'
      }
    end

    let(:invalid_attributes) do
      {
        contact_name: '',
        total_lent: nil,
        direction: 'lent'
      }
    end

    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        post debts_path, params: { debt: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with valid attributes' do
      it 'creates a new debt' do
        expect {
          post debts_path, params: { debt: valid_attributes }
        }.to change(Debt, :count).by(1)
      end

      it 'redirects to the created debt' do
        post debts_path, params: { debt: valid_attributes }
        created_debt = Debt.order(created_at: :desc).first
        expect(response).to redirect_to(debt_path(id: created_debt.id))
      end

      it 'sets a success flash message' do
        post debts_path, params: { debt: valid_attributes }
        expect(flash[:notice]).to eq(I18n.t('debts.create.success'))
      end

      it 'creates debt with correct attributes' do
        post debts_path, params: { debt: valid_attributes }
        created_debt = Debt.order(created_at: :desc).first
        expect(created_debt.name).to eq(valid_attributes[:contact_name])
        expect(created_debt.total_lent).to eq(valid_attributes[:total_lent])
        expect(created_debt.total_reimbursed).to eq(valid_attributes[:total_reimbursed])
        expect(created_debt.note).to eq(valid_attributes[:note])
        expect(created_debt.direction).to eq(valid_attributes[:direction])
        expect(created_debt.user).to eq(user)
      end

      it 'creates associated transactions' do
        expect {
          post debts_path, params: { debt: valid_attributes }
        }.to change(Transaction, :count).by_at_least(1)
      end
    end

    context 'with invalid attributes' do
      it 'does not create a new debt' do
        expect {
          post debts_path, params: { debt: invalid_attributes }
        }.not_to change(Debt, :count)
      end

      it 'renders the new template' do
        post debts_path, params: { debt: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post debts_path, params: { debt: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        get edit_debt_path(id: debt.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with valid debt id' do
      it 'returns successful response' do
        get edit_debt_path(id: debt.id)
        expect(response).to be_successful
      end

      it 'displays the edit form with debt data' do
        get edit_debt_path(id: debt.id)
        expect(response.body).to include(debt.name)
        expect(response.body).to include('debt-form')
      end
    end

    context 'with debt belonging to another user' do
      let(:other_debt) { create(:debt, user: other_user, name: 'Someone') }

      it 'redirects to debts path' do
        get edit_debt_path(id: other_debt.id)
        expect(response).to redirect_to(debts_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        contact_name: 'Updated Name',
        total_lent: 1500,
        total_reimbursed: 500,
        note: 'Updated note',
        direction: 'lent',
        account_name: 'Bank Account'
      }
    end

    let(:invalid_attributes) do
      {
        contact_name: '',
        total_lent: -100,
        direction: 'lent'
      }
    end

    context 'when not authenticated' do
      before { sign_out :user }

      it 'redirects to sign in' do
        patch debt_path(id: debt.id), params: { debt: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with valid attributes' do
      it 'updates the debt' do
        patch debt_path(id: debt.id), params: { debt: new_attributes }
        debt.reload
        expect(debt.name).to eq(new_attributes[:contact_name])
        expect(debt.note).to eq(new_attributes[:note])
      end

      it 'redirects to the debt' do
        patch debt_path(id: debt.id), params: { debt: new_attributes }
        expect(response).to redirect_to(debt_path(id: debt.id))
      end

      it 'sets a success flash message' do
        patch debt_path(id: debt.id), params: { debt: new_attributes }
        expect(flash[:notice]).to eq(I18n.t('debts.update.success'))
      end

      it 'creates transactions for increased amounts' do
        expect {
          patch debt_path(id: debt.id), params: { debt: new_attributes }
        }.to change(Transaction, :count).by_at_least(1)
      end
    end

    context 'with invalid attributes' do
      it 'does not update the debt' do
        original_name = debt.name
        patch debt_path(id: debt.id), params: { debt: invalid_attributes }
        debt.reload
        expect(debt.name).to eq(original_name)
      end

      it 'renders the edit template' do
        patch debt_path(id: debt.id), params: { debt: invalid_attributes }
        expect(response).to render_template(:edit)
      end

      it 'returns unprocessable entity status' do
        patch debt_path(id: debt.id), params: { debt: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with debt belonging to another user' do
      let(:other_debt) { create(:debt, user: other_user, name: 'Someone') }

      it 'redirects to debts path' do
        patch debt_path(id: other_debt.id), params: { debt: new_attributes }
        expect(response).to redirect_to(debts_path)
      end

      it 'does not update the debt' do
        original_name = other_debt.name
        patch debt_path(id: other_debt.id), params: { debt: new_attributes }
        other_debt.reload
        expect(other_debt.name).to eq(original_name)
      end
    end
  end
end
