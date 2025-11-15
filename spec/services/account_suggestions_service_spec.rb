# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountSuggestionsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#all' do
    context 'when user has no accounts' do
      it 'returns only template suggestions' do
        results = service.all
        templates = Account.templates(I18n.locale).values

        expect(results).to all(be_a(String))
        expect(results.size).to be >= 100
        expect(results.uniq.size).to eq(results.size)
      end
    end

    context 'when user has accounts' do
      before do
        create(:account, user: user, name: 'My Savings')
        create(:account, user: user, name: 'My Checking')
      end

      it 'returns user accounts and templates combined' do
        results = service.all

        expect(results).to include('My Savings')
        expect(results).to include('My Checking')
        expect(results.size).to be > 2 # Should include templates too
      end

      it 'returns unique suggestions (no duplicates)' do
        results = service.all

        # Check for duplicates by counting occurrences
        duplicates = results.group_by(&:itself).select { |_, v| v.size > 1 }.keys

        expect(duplicates).to be_empty, "Found duplicate suggestions: #{duplicates.join(', ')}"
        expect(results.uniq.size).to eq(results.size)
      end

      it 'handles duplicates between user accounts and templates' do
        # Create a user account that matches a template name
        template_name = Account.templates(I18n.locale).values.first

        create(:account, user: user, name: template_name)

        results = service.all

        # Should only appear once, not twice
        expect(results.count(template_name)).to eq(1)
        expect(results.count { |name| name == template_name }).to eq(1)
      end

      it 'orders user accounts by most recent first' do
        older_account = create(:account, user: user, name: 'Older Account', updated_at: 2.days.ago)
        newer_account = create(:account, user: user, name: 'Newer Account', updated_at: 1.day.ago)

        results = service.all
        user_account_names = results.take(4) # First few should be user accounts

        expect(user_account_names.index('Newer Account')).to be < user_account_names.index('Older Account')
      end
    end

    context 'when user account name matches template' do
      before do
        template_name = Account.templates(I18n.locale).values.first
        create(:account, user: user, name: template_name)
      end

      it 'does not duplicate the account' do
        results = service.all
        template_name = Account.templates(I18n.locale).values.first

        expect(results.count(template_name)).to eq(1)
      end
    end
  end

  describe '#all_with_balances' do
    context 'when user has no accounts' do
      it 'returns only template suggestions with zero balances' do
        results = service.all_with_balances
        templates = Account.templates(I18n.locale).values

        expect(results).to all(have_key(:name))
        expect(results).to all(have_key(:balance))
        expect(results.map { |r| r[:name] }).to match_array(templates)
        expect(results.map { |r| r[:balance] }).to all(eq(0))
      end

      it 'returns hashes with name and balance keys' do
        results = service.all_with_balances

        expect(results.first).to be_a(Hash)
        expect(results.first.keys).to match_array([:name, :balance])
      end
    end

    context 'when user has accounts' do
      before do
        create(:account, user: user, name: 'My Savings', balance: 1000.0)
        create(:account, user: user, name: 'My Checking', balance: 500.0)
      end

      it 'returns user accounts with their actual balances' do
        results = service.all_with_balances

        savings = results.find { |r| r[:name] == 'My Savings' }
        checking = results.find { |r| r[:name] == 'My Checking' }

        expect(savings[:balance]).to eq(1000.0)
        expect(checking[:balance]).to eq(500.0)
      end

      it 'returns templates with zero balance' do
        results = service.all_with_balances
        template_name = Account.templates(I18n.locale).values.first

        # Skip user accounts to get to templates
        user_account_names = ['My Savings', 'My Checking']
        template_result = results.find { |r| r[:name] == template_name && !user_account_names.include?(r[:name]) }

        expect(template_result[:balance]).to eq(0) if template_result
      end

      it 'returns user accounts and templates' do
        results = service.all_with_balances
        names = results.map { |r| r[:name] }

        # Check that user accounts appear
        expect(names).to include('My Savings', 'My Checking')

        # Check that user accounts appear with correct balances
        savings = results.find { |r| r[:name] == 'My Savings' }
        checking = results.find { |r| r[:name] == 'My Checking' }

        expect(savings[:balance]).to eq(1000.0)
        expect(checking[:balance]).to eq(500.0)
      end

      it 'orders user accounts by most recent first' do
        # Recreate accounts with specific timing to ensure proper ordering
        older = create(:account, user: user, name: 'Older Account', balance: 200.0, updated_at: 5.days.ago)
        newer = create(:account, user: user, name: 'Newer Account', balance: 300.0, updated_at: 1.day.ago)

        results = service.all_with_balances

        # Find indices of our test accounts
        newer_index = results.index { |r| r[:name] == 'Newer Account' }
        older_index = results.index { |r| r[:name] == 'Older Account' }

        expect(newer_index).to be < older_index
      end
    end

    context 'when user account name matches template' do
      before do
        template_name = Account.templates(I18n.locale).values.first
        create(:account, user: user, name: template_name, balance: 750.0)
      end

      it 'does not duplicate the account' do
        results = service.all_with_balances
        template_name = Account.templates(I18n.locale).values.first
        matching_results = results.select { |r| r[:name] == template_name }

        expect(matching_results.size).to eq(1)
      end

      it 'uses the user account balance, not zero' do
        results = service.all_with_balances
        template_name = Account.templates(I18n.locale).values.first
        result = results.find { |r| r[:name] == template_name }

        expect(result[:balance]).to eq(750.0)
      end
    end

    context 'with negative balances' do
      before do
        create(:account, user: user, name: 'Overdraft Account', balance: -100.0)
      end

      it 'includes accounts with negative balances' do
        results = service.all_with_balances
        overdraft = results.find { |r| r[:name] == 'Overdraft Account' }

        expect(overdraft[:balance]).to eq(-100.0)
      end
    end
  end

  describe '#defaults' do
    context 'when user has no accounts' do
      it 'returns up to 10 template suggestions' do
        results = service.defaults

        expect(results.size).to be <= 10
      end
    end

    context 'when user has fewer than 10 accounts' do
      before do
        3.times { |i| create(:account, user: user, name: "Account #{i + 1}") }
      end

      it 'returns all user accounts plus templates to reach 10' do
        results = service.defaults

        expect(results.size).to eq(10)
        expect(results.take(3)).to match_array(['Account 1', 'Account 2', 'Account 3'])
      end

      it 'does not include duplicate templates already used by user' do
        template_name = Account.templates(I18n.locale).values.first
        create(:account, user: user, name: template_name)

        results = service.defaults

        expect(results.count(template_name)).to eq(1)
      end

      it 'fills remaining slots with available templates' do
        results = service.defaults
        user_account_count = user.accounts.count
        template_count = results.size - user_account_count

        expect(template_count).to eq(10 - user_account_count)
      end
    end

    context 'when user has exactly 10 accounts' do
      before do
        10.times { |i| create(:account, user: user, name: "Account #{i + 1}") }
      end

      it 'returns exactly 10 user accounts with no templates' do
        results = service.defaults

        expect(results.size).to eq(10)
        expect(results).to all(start_with('Account'))
      end
    end

    context 'when user has more than 10 accounts' do
      before do
        15.times { |i| create(:account, user: user, name: "Account #{i + 1}") }
      end

      it 'returns all user accounts (more than 10) with no templates' do
        results = service.defaults

        expect(results.size).to eq(15)
        expect(results).to all(start_with('Account'))
      end

      it 'does not include any template suggestions' do
        results = service.defaults
        templates = Account.templates(I18n.locale).values

        templates.each do |template|
          expect(results).not_to include(template)
        end
      end
    end

    context 'when user has accounts ordered by update time' do
      before do
        create(:account, user: user, name: 'Oldest', updated_at: 5.days.ago)
        create(:account, user: user, name: 'Middle', updated_at: 3.days.ago)
        create(:account, user: user, name: 'Newest', updated_at: 1.day.ago)
      end

      it 'returns accounts in most recently updated order' do
        results = service.defaults

        expect(results[0]).to eq('Newest')
        expect(results[1]).to eq('Middle')
        expect(results[2]).to eq('Oldest')
      end
    end
  end

  describe '#defaults_with_balances' do
    context 'when user has no accounts' do
      it 'returns up to 10 template suggestions with zero balances' do
        results = service.defaults_with_balances

        expect(results.size).to eq(10)
        expect(results).to all(have_key(:name))
        expect(results).to all(have_key(:balance))
        expect(results.map { |r| r[:balance] }).to all(eq(0))
      end

      it 'returns templates as hashes' do
        results = service.defaults_with_balances

        expect(results.first).to be_a(Hash)
        expect(results.first.keys).to match_array([:name, :balance])
      end
    end

    context 'when user has fewer than 10 accounts' do
      before do
        create(:account, user: user, name: 'Account 1', balance: 100.0)
        create(:account, user: user, name: 'Account 2', balance: 200.0)
        create(:account, user: user, name: 'Account 3', balance: 300.0)
      end

      it 'returns exactly 10 results' do
        results = service.defaults_with_balances

        expect(results.size).to eq(10)
      end

      it 'returns all user accounts with their balances first' do
        results = service.defaults_with_balances

        expect(results[0]).to eq({ name: 'Account 3', balance: 300.0 })
        expect(results[1]).to eq({ name: 'Account 2', balance: 200.0 })
        expect(results[2]).to eq({ name: 'Account 1', balance: 100.0 })
      end

      it 'fills remaining slots with templates at zero balance' do
        results = service.defaults_with_balances
        template_results = results[3..-1] # Get results after user accounts

        expect(template_results.size).to eq(7)
        expect(template_results.map { |r| r[:balance] }).to all(eq(0))
      end

      it 'does not duplicate templates already used by user' do
        template_name = Account.templates(I18n.locale).values.first
        create(:account, user: user, name: template_name, balance: 500.0)

        results = service.defaults_with_balances
        matching_results = results.select { |r| r[:name] == template_name }

        expect(matching_results.size).to eq(1)
        expect(matching_results.first[:balance]).to eq(500.0)
      end
    end

    context 'when user has exactly 10 accounts' do
      before do
        10.times { |i| create(:account, user: user, name: "Account #{i + 1}", balance: (i + 1) * 100.0) }
      end

      it 'returns exactly 10 user accounts with their balances' do
        results = service.defaults_with_balances

        expect(results.size).to eq(10)
        expect(results).to all(have_key(:name))
        expect(results).to all(have_key(:balance))
      end

      it 'does not include any templates' do
        results = service.defaults_with_balances
        templates = Account.templates(I18n.locale).values

        result_names = results.map { |r| r[:name] }
        templates.each do |template|
          expect(result_names).not_to include(template)
        end
      end

      it 'returns accounts with their actual balances' do
        results = service.defaults_with_balances

        expect(results.map { |r| r[:balance] }).to all(be > 0)
        expect(results.last[:balance]).to eq(100.0) # Oldest account (Account 1)
      end
    end

    context 'when user has more than 10 accounts' do
      before do
        15.times { |i| create(:account, user: user, name: "Account #{i + 1}", balance: (i + 1) * 50.0) }
      end

      it 'returns all user accounts (more than 10)' do
        results = service.defaults_with_balances

        expect(results.size).to eq(15)
      end

      it 'does not include any template suggestions' do
        results = service.defaults_with_balances
        templates = Account.templates(I18n.locale).values

        result_names = results.map { |r| r[:name] }
        templates.each do |template|
          expect(result_names).not_to include(template)
        end
      end

      it 'returns all accounts with their actual balances' do
        results = service.defaults_with_balances

        expect(results).to all(be_a(Hash))
        expect(results.map { |r| r[:balance] }).to all(be > 0)
      end
    end

    context 'when user has accounts ordered by update time' do
      before do
        create(:account, user: user, name: 'Oldest', balance: 100.0, updated_at: 5.days.ago)
        create(:account, user: user, name: 'Middle', balance: 200.0, updated_at: 3.days.ago)
        create(:account, user: user, name: 'Newest', balance: 300.0, updated_at: 1.day.ago)
      end

      it 'returns accounts in most recently updated order with balances' do
        results = service.defaults_with_balances

        expect(results[0]).to eq({ name: 'Newest', balance: 300.0 })
        expect(results[1]).to eq({ name: 'Middle', balance: 200.0 })
        expect(results[2]).to eq({ name: 'Oldest', balance: 100.0 })
      end
    end

    context 'with negative and zero balances' do
      before do
        create(:account, user: user, name: 'Overdraft', balance: -50.0)
        create(:account, user: user, name: 'Empty', balance: 0.0)
        create(:account, user: user, name: 'Positive', balance: 100.0)
      end

      it 'includes accounts with negative balances' do
        results = service.defaults_with_balances
        overdraft = results.find { |r| r[:name] == 'Overdraft' }

        expect(overdraft[:balance]).to eq(-50.0)
      end

      it 'includes accounts with zero balances' do
        results = service.defaults_with_balances
        empty = results.find { |r| r[:name] == 'Empty' }

        expect(empty[:balance]).to eq(0.0)
      end

      it 'distinguishes user account with zero balance from template' do
        results = service.defaults_with_balances
        user_empty = results.find { |r| r[:name] == 'Empty' }

        # User account should appear before templates (ordered by updated_at)
        expect(results.index(user_empty)).to be < 3
      end
    end
  end
end
