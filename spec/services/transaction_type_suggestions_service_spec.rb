# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionTypeSuggestionsService do
  let(:user) { create(:user) }
  let(:kind) { 'expense' }
  let(:service) { described_class.new(user, kind) }

  describe '#all' do
    context 'when user has no transaction types' do
      it 'returns only template suggestions for the given kind' do
        results = service.all
        templates = TransactionType.templates(I18n.locale)
        expense_templates = templates.select { |_k, attrs| attrs[:kind] == kind }.map { |_k, attrs| attrs[:name] }

        expect(results).to match_array(expense_templates)
      end
    end

    context 'when user has transaction types' do
      before do
        create(:transaction_type, user: user, kind: 'expense', name: 'My Groceries')
        create(:transaction_type, user: user, kind: 'expense', name: 'My Rent')
        create(:transaction_type, user: user, kind: 'income', name: 'My Salary')
      end

      it 'returns only user transaction types matching the kind' do
        results = service.all

        expect(results).to include('My Groceries')
        expect(results).to include('My Rent')
        expect(results).not_to include('My Salary') # Different kind
      end

      it 'combines user types with templates for the same kind' do
        results = service.all

        expect(results).to include('My Groceries')
        expect(results.size).to be > 2 # Should include templates too
      end

      it 'returns unique suggestions (no duplicates)' do
        results = service.all

        # Check for duplicates by counting occurrences
        duplicates = results.group_by(&:itself).select { |_, v| v.size > 1 }.keys

        expect(duplicates).to be_empty, "Found duplicate suggestions: #{duplicates.join(', ')}"
        expect(results.uniq.size).to eq(results.size)
      end

      it 'handles duplicates between user types and templates' do
        # Create a user type that matches a template name
        template_name = TransactionType.templates(I18n.locale)
          .find { |_k, attrs| attrs[:kind] == kind }
          &.last&.dig(:name)

        skip "No template found for kind #{kind}" unless template_name

        create(:transaction_type, user: user, kind: kind, name: template_name)

        results = service.all

        # Should only appear once, not twice
        expect(results.count(template_name)).to eq(1)
        expect(results.count { |name| name == template_name }).to eq(1)
      end

      it 'orders user types by most recent first' do
        older_type = create(:transaction_type, user: user, kind: 'expense', name: 'Older Type', updated_at: 2.days.ago)
        newer_type = create(:transaction_type, user: user, kind: 'expense', name: 'Newer Type', updated_at: 1.day.ago)

        results = service.all
        user_type_names = results.take(4) # First few should be user types

        expect(user_type_names.index('Newer Type')).to be < user_type_names.index('Older Type')
      end
    end

    context 'when user transaction type name matches template' do
      before do
        template_name = TransactionType.templates(I18n.locale)
          .find { |_k, attrs| attrs[:kind] == kind }
          &.last&.dig(:name)
        create(:transaction_type, user: user, kind: kind, name: template_name) if template_name
      end

      it 'does not duplicate the transaction type' do
        results = service.all
        template_name = TransactionType.templates(I18n.locale)
          .find { |_k, attrs| attrs[:kind] == kind }
          &.last&.dig(:name)

        expect(results.count(template_name)).to eq(1) if template_name
      end
    end

    context 'with different kinds' do
      let(:expense_service) { described_class.new(user, 'expense') }
      let(:income_service) { described_class.new(user, 'income') }

      before do
        create(:transaction_type, user: user, kind: 'expense', name: 'Groceries')
        create(:transaction_type, user: user, kind: 'income', name: 'Salary')
      end

      it 'returns different suggestions based on kind' do
        expense_results = expense_service.all
        income_results = income_service.all

        expect(expense_results).to include('Groceries')
        expect(expense_results).not_to include('Salary')

        expect(income_results).to include('Salary')
        expect(income_results).not_to include('Groceries')
      end
    end
  end

  describe '#defaults' do
    context 'when user has no transaction types' do
      it 'returns up to 15 default template suggestions' do
        results = service.defaults

        expect(results.size).to be <= 15
      end

      it 'uses default template keys defined in TransactionType model' do
        default_keys = TransactionType.default_template_keys(kind)
        results = service.defaults

        expect(results.size).to be <= default_keys.size
      end
    end

    context 'when user has fewer than 15 transaction types' do
      before do
        3.times { |i| create(:transaction_type, user: user, kind: kind, name: "Type #{i + 1}") }
      end

      it 'returns all user types plus templates to reach 15' do
        results = service.defaults

        expect(results.size).to eq(15)
        expect(results.take(3)).to match_array(['Type 1', 'Type 2', 'Type 3'])
      end

      it 'does not include duplicate templates already used by user' do
        default_keys = TransactionType.default_template_keys(kind)
        template_name = TransactionType.templates(I18n.locale)
          .find { |key, attrs| default_keys.include?(key.to_s) && attrs[:kind] == kind }
          &.last&.dig(:name)

        create(:transaction_type, user: user, kind: kind, name: template_name) if template_name
        results = service.defaults

        expect(results.count(template_name)).to eq(1) if template_name
      end

      it 'fills remaining slots with available default templates' do
        results = service.defaults
        user_type_count = user.transaction_types.where(kind: kind).count
        template_count = results.size - user_type_count

        expect(template_count).to eq(15 - user_type_count)
      end
    end

    context 'when user has exactly 15 transaction types' do
      before do
        15.times { |i| create(:transaction_type, user: user, kind: kind, name: "Type #{i + 1}") }
      end

      it 'returns exactly 15 user types with no templates' do
        results = service.defaults

        expect(results.size).to eq(15)
        expect(results).to all(start_with('Type'))
      end
    end

    context 'when user has more than 15 transaction types' do
      before do
        15.times { |i| create(:transaction_type, user: user, kind: kind, name: "Type #{i + 1}") }
      end

      it 'returns all user types (more than 15) with no templates' do
        results = service.defaults

        expect(results.size).to eq(15)
        expect(results).to all(start_with('Type'))
      end

      it 'does not include any template suggestions' do
        results = service.defaults
        default_keys = TransactionType.default_template_keys(kind)
        templates = TransactionType.templates(I18n.locale)
        default_template_names = default_keys.filter_map do |key|
          templates.dig(key.to_sym, :name) if templates.key?(key.to_sym)
        end

        default_template_names.each do |template|
          # User types should not match template names since we created custom ones
          expect(results).not_to include(template)
        end
      end
    end

    context 'when user has transaction types ordered by update time' do
      before do
        create(:transaction_type, user: user, kind: kind, name: 'Oldest', updated_at: 5.days.ago)
        create(:transaction_type, user: user, kind: kind, name: 'Middle', updated_at: 3.days.ago)
        create(:transaction_type, user: user, kind: kind, name: 'Newest', updated_at: 1.day.ago)
      end

      it 'returns types in most recently updated order' do
        results = service.defaults

        expect(results[0]).to eq('Newest')
        expect(results[1]).to eq('Middle')
        expect(results[2]).to eq('Oldest')
      end
    end

    context 'with different kinds having different default templates' do
      it 'returns different default suggestions for expense vs income' do
        expense_service = described_class.new(user, 'expense')
        income_service = described_class.new(user, 'income')

        expense_results = expense_service.defaults
        income_results = income_service.defaults

        # They should be different sets
        expect(expense_results).not_to eq(income_results)

        # Expense should have more options (15 default keys)
        expect(expense_results.size).to be > income_results.size
      end
    end
  end
end
