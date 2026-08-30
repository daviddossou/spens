# frozen_string_literal: true

module Transactions
  # One-field editors for the transaction detail page. Each fact (category,
  # account, date) opens alone in a bottom sheet; submitting PATCHes the regular
  # transactions#update with just that field, so every edit goes through the
  # same ledger-safe path as the full form.
  class FactsController < ApplicationController
    before_action :authenticate_user!

    FACTS = %w[category account date].freeze

    def edit
      @transaction = current_space.transactions.includes(:transaction_type, :account).find(params[:id])
      @fact = params[:fact]
      head :not_found and return unless FACTS.include?(@fact)

      @form = TransactionForm.new(current_space, transaction: @transaction)
      @form.user = current_user
    end
  end
end
