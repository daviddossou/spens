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

        expect(results).to match_array(templates)
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
end
