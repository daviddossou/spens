# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountLineComponent, type: :component do
  let(:user) { create(:user) }
  let(:transaction_form) do
    Onboarding::TransactionForm.new(
      user: user,
      amount: 50_000.00,
      transaction_date: Date.current,
      account_name: 'Cash Wallet',
      transaction_type_name: Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_NAME,
      transaction_type_kind: Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_KIND
    )
  end

  # Create a form builder for the TransactionForm object
  let(:form) { mock_form_builder(transaction_form) }

  describe '#initialize' do
    it 'accepts all required parameters' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'XOF',
        can_remove: false
      )

      expect(component.instance_variable_get(:@form)).to eq(form)
      expect(component.instance_variable_get(:@index)).to eq(0)
      expect(component.instance_variable_get(:@transaction)).to eq(transaction_form)
      expect(component.instance_variable_get(:@currency)).to eq('XOF')
      expect(component.instance_variable_get(:@can_remove)).to be false
    end

    it 'defaults can_remove to false' do
      component = described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
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
        transaction: transaction_form,
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
        transaction: transaction_form,
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
        transaction: transaction_form,
        currency: 'XOF'
      ))

      expect(rendered.css('div.account-line')).to be_present
      expect(rendered.css('div[data-onboarding--account-setup-target="accountLine"]')).to be_present
    end

    it 'renders account name field' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'XOF'
      ))

      # InputFieldComponent renders the actual field
      expect(rendered.css('input[type="text"]')).to be_present
    end

    it 'renders amount field with currency prepend' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="number"]')).to be_present
      expect(rendered.to_html).to include('XOF')
    end

    it 'renders hidden transaction_date field' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="hidden"][name*="transaction_date"]')).to be_present
    end

    it 'renders hidden transaction_type fields' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'XOF'
      ))

      expect(rendered.css('input[type="hidden"][name*="transaction_type_name"]')).to be_present
      expect(rendered.css('input[type="hidden"][name*="transaction_type_kind"]')).to be_present
    end

    context 'when can_remove is false' do
      it 'does not render remove button' do
        rendered = render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction_form,
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
          transaction: transaction_form,
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
          transaction: transaction_form,
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
        transaction: transaction_form,
        currency: 'XOF'
      ))

      expect(rendered.to_html).to include('XOF')
    end

    it 'renders with USD currency' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'USD'
      ))

      expect(rendered.to_html).to include('USD')
    end

    it 'renders with EUR currency' do
      rendered = render_inline(described_class.new(
        form: form,
        index: 0,
        transaction: transaction_form,
        currency: 'EUR'
      ))

      expect(rendered.to_html).to include('EUR')
    end
  end

  describe 'integration with form object' do
    it 'works with TransactionForm object' do
      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction_form,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'renders multiple account lines with different indexes' do
      transaction_forms = 3.times.map do |i|
        Onboarding::TransactionForm.new(
          user: user,
          amount: 10_000 * (i + 1),
          transaction_date: Date.current,
          account_name: "Account #{i + 1}",
          transaction_type_name: Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_NAME,
          transaction_type_kind: Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_KIND
        )
      end

      transaction_forms.each_with_index do |txn_form, index|
        form_builder = mock_form_builder(txn_form)
        component = described_class.new(
          form: form_builder,
          index: index,
          transaction: txn_form,
          currency: 'XOF',
          can_remove: index > 0
        )

        expect { render_inline(component) }.not_to raise_error
      end
    end
  end

  describe 'edge cases' do
    it 'handles transaction with existing account name' do
      transaction_form.account_name = 'My Existing Account'

      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction_form,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles transaction with zero amount' do
      transaction_form.amount = 0

      expect do
        render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction_form,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles large index numbers' do
      expect do
        render_inline(described_class.new(
          form: form,
          index: 999,
          transaction: transaction_form,
          currency: 'XOF'
        ))
      end.not_to raise_error
    end

    it 'handles different currency symbols' do
      currencies = [ 'XOF', 'USD', 'EUR', 'GBP', 'NGN', 'GHS', 'XAF' ]

      currencies.each do |currency|
        rendered = render_inline(described_class.new(
          form: form,
          index: 0,
          transaction: transaction_form,
          currency: currency
        ))

        expect(rendered.to_html).to include(currency)
      end
    end
  end
end
