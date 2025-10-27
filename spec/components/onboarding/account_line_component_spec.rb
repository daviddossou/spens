# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountLineComponent, type: :component do
  let(:user) { create(:user) }
  let(:transaction) do
    Transaction.new(
      amount: 50_000.00,
      transaction_date: Date.current,
      user: user
    ).tap do |t|
      t.build_account(name: 'Cash Wallet', user: user)
      t.build_transaction_type(
        name: Onboarding::AccountSetupForm::TRANSACTION_TYPE_NAME,
        kind: TransactionType::KIND_TRANSFER_IN,
        user: user
      )
    end
  end

  # Create a form builder for a Transaction object
  let(:form) { mock_form_builder(transaction) }

  describe '#initialize' do
    it 'accepts all required parameters' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF',
        can_remove: false
      )

      expect(component.instance_variable_get(:@form)).to eq(form)
      expect(component.instance_variable_get(:@index)).to eq(0)
      expect(component.instance_variable_get(:@transaction)).to eq(transaction)
      expect(component.instance_variable_get(:@currency)).to eq('XOF')
      expect(component.instance_variable_get(:@can_remove)).to be false
    end

    it 'defaults can_remove to false' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      )

      expect(component.instance_variable_get(:@can_remove)).to be false
    end
  end

  describe '#account_suggestions' do
    it 'returns account template values from i18n' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      )

      suggestions = component.account_suggestions

      expect(suggestions).to be_an(Array)
      expect(suggestions).not_to be_empty
      expect(suggestions).to all(be_a(String))
    end

    it 'includes expected account templates' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      )

      I18n.with_locale(:en) do
        suggestions = component.account_suggestions

        # Check that common account types are included
        expect(suggestions).to include(a_string_matching(/cash|wallet/i))
        expect(suggestions).to include(a_string_matching(/bank|compte|account/i))
      end
    end
  end

  describe 'rendering' do
    it 'renders the account line container' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      expect(rendered.css('div.account-line')).to be_present
      expect(rendered.css('div[data-onboarding--account-setup-target="accountLine"]')).to be_present
    end

    it 'renders account name field' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      # InputFieldComponent renders the actual field
      expect(rendered.css('input[type="text"]')).to be_present
    end

    it 'renders amount field with currency prepend' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="number"]')).to be_present
      expect(rendered.to_html).to include('XOF')
    end

    it 'renders hidden transaction_date field' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="hidden"][name*="transaction_date"]')).to be_present
    end

    it 'renders hidden transaction_type fields' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="hidden"][name*="[name]"]')).to be_present
      expect(rendered.css('input[type="hidden"][name*="[kind]"]')).to be_present
    end

    context 'when can_remove is false' do
      it 'does not render remove button' do
        rendered = render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction,
          currency: 'XOF',
          can_remove: false
        ))

        expect(rendered.css('.account-line__remove-link')).not_to be_present
      end
    end

    context 'when can_remove is true' do
      it 'renders remove button' do
        rendered = render_inline(described_class.new(
          form: form,
          index: 1,
          transaction: transaction,
          currency: 'XOF',
          can_remove: true
        ))

        expect(rendered.css('.account-line__remove-link')).to be_present
        expect(rendered.css('button[type="button"]')).to be_present
      end

      it 'remove button has correct action' do
        rendered = render_inline(described_class.new(
          form: form,
          index: 1,
          transaction: transaction,
          currency: 'XOF',
          can_remove: true
        ))

        expect(rendered.css('button[data-action*="removeLine"]')).to be_present
      end
    end
  end

  describe 'currency handling' do
    it 'renders with XOF currency' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF'
      ))

      expect(rendered.to_html).to include('XOF')
    end

    it 'renders with USD currency' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'USD'
      ))

      expect(rendered.to_html).to include('USD')
    end

    it 'renders with EUR currency' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'EUR'
      ))

      expect(rendered.to_html).to include('EUR')
    end
  end

  describe 'integration with form object' do
    it 'works with Transaction object' do
      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'renders multiple account lines with different indexes' do
      transactions = 3.times.map do |i|
        Transaction.new(
          amount: 10_000 * (i + 1),
          transaction_date: Date.current,
          user: user
        ).tap do |t|
          t.build_account(name: "Account #{i + 1}", user: user)
          t.build_transaction_type(
            name: Onboarding::AccountSetupForm::TRANSACTION_TYPE_NAME,
            kind: TransactionType::KIND_TRANSFER_IN,
            user: user
          )
        end
      end

      transactions.each_with_index do |txn, index|
        form_builder = mock_form_builder(txn)
        component = described_class.new(
          form: form_builder,
          index: index,
          transaction: txn,
          currency: 'XOF',
          can_remove: index > 0
        )

        expect { render_inline(component) }.not_to raise_error
      end
    end
  end

  describe 'edge cases' do
    it 'handles transaction with existing account name' do
      transaction.account.name = 'My Existing Account'

      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles transaction with zero amount' do
      transaction.amount = 0

      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles large index numbers' do
      expect do
        render_inline(described_class.new(
          form: form,
          index: 999,
          transaction: transaction,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles different currency symbols' do
      currencies = ['XOF', 'USD', 'EUR', 'GBP', 'NGN', 'GHS', 'XAF']

      currencies.each do |currency|
        rendered = render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction,
          currency: currency
        ))

        expect(rendered.to_html).to include(currency)
      end
    end
  end
end
