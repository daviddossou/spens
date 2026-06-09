# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionTypeSuggestionsService do
  let(:user) { create(:user) }
  let(:kind) { 'expense' }
  let(:service) { described_class.new(user, kind) }

  # "Recorded" = a category that appears on at least one transaction.
  def record(name, kind: 'expense', **attrs)
    type = create(:transaction_type, user: user, kind: kind, name: name, **attrs)
    create(:transaction, space: type.space, transaction_type: type)
    type
  end

  describe '#options (search universe)' do
    it 'includes every taxonomy subcategory as a flat option' do
      values = service.options.map { |o| o[:value] }
      expect(values).to include(TransactionTaxonomy.name('moto_taxi'))
      expect(values).to include(TransactionTaxonomy.name('groceries'))
    end

    it 'carries alias phrases so a merchant surfaces its category' do
      groceries = service.options.find { |o| o[:value] == TransactionTaxonomy.name('groceries') }
      expect(groceries[:aliases]).to include('carrefour')
    end

    it 'is flat — no option carries an optgroup' do
      expect(service.options).to all(satisfy { |o| !o.key?(:optgroup) })
    end

    it "includes the user's own recorded categories" do
      record('My Niche Thing')
      expect(service.options.map { |o| o[:value] }).to include('My Niche Thing')
    end

    it 'lists a recorded taxonomy category once (the canonical option, not a custom dup)' do
      record(TransactionTaxonomy.name('moto_taxi'), template_key: 'moto_taxi')
      name = TransactionTaxonomy.name('moto_taxi')
      expect(service.options.map { |o| o[:value] }.count(name)).to eq(1)
    end
  end

  describe '#default_options' do
    context 'when the user has recorded nothing' do
      it 'shows the 20 most common categories for the kind' do
        results = service.default_options
        common = TransactionType.default_template_keys('expense').map { |k| TransactionTaxonomy.name(k) }

        expect(results.size).to eq(20)
        expect(results.map { |o| o[:value] }).to match_array(common)
      end
    end

    context 'with a few recorded categories' do
      before do
        record('Older', updated_at: 3.days.ago)
        record('Newer', updated_at: 1.day.ago)
      end

      it "leads with the user's own categories, newest first" do
        expect(service.default_options.first(2).map { |o| o[:value] }).to eq(%w[Newer Older])
      end

      it 'tops up to 20 with common categories' do
        expect(service.default_options.size).to eq(20)
      end
    end

    context 'with more than 20 recorded categories' do
      before { 21.times { |i| record("Cat #{i}", updated_at: i.minutes.ago) } }

      it "shows only the user's own, capped at 20" do
        results = service.default_options
        expect(results.size).to eq(20)
        expect(results.map { |o| o[:value] }).to all(start_with('Cat'))
      end
    end

    it 'excludes categories the user has not actually used' do
      create(:transaction_type, user: user, kind: 'expense', name: 'Never Used') # no transaction
      expect(service.default_options.map { |o| o[:value] }).not_to include('Never Used')
    end

    it 'does not duplicate a recorded category that is also a common default' do
      record(TransactionTaxonomy.name('groceries'), template_key: 'groceries')
      name = TransactionTaxonomy.name('groceries')
      values = service.default_options.map { |o| o[:value] }

      expect(values.count(name)).to eq(1)
      expect(values.size).to eq(20)
    end

    it 'returns different common defaults for income vs expense' do
      expense = described_class.new(user, 'expense').default_options.map { |o| o[:value] }
      income  = described_class.new(user, 'income').default_options.map { |o| o[:value] }
      expect(expense).not_to eq(income)
    end
  end
end
