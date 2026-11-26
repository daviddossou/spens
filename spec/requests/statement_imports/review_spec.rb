# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Statement import review", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let!(:bank) { create(:account, space: space, name: "Bank", balance: 100_000) }
  let!(:groceries) { create(:transaction_type, space: space, name: "Groceries", kind: :expense) }
  let(:import) { create(:statement_import, user: user, space: space, account: bank, status: "ready", captures: [ image_upload ]) }

  before do
    allow(StatementImports::Reader).to receive(:enabled?).and_return(true)
    sign_in user, scope: :user
  end

  def line(**attrs)
    import.lines.create!({ position: import.lines.count + 1, capture_index: 0, status: "ok", kind: "expense", amount: -2000,
                           currency: "XOF", occurred_on: Date.new(2026, 11, 2), label: "Carrefour", account: bank,
                           transaction_type_name: "Groceries", category_source: "rules", decision: "pending" }.merge(attrs))
  end

  describe "the review screen" do
    it "puts what needs a look first, keeps the rest by date, and sets aside the rest with a reason" do
      line(label: "Uber Eats", transaction_type_name: nil, category_source: nil)
      line(label: "Carrefour Market")
      line(label: "Amazon", status: "card_check", amount: 0)
      line(label: "Picard", status: "declined", amount: -615)

      get statement_import_path(id: import.id)

      body = response.body
      expect(body).to include("To check", "Choose a category", "The rest · by date", "Transfers")
      expect(body).to include("card check", "declined", "Save 2 transactions", "Swipe a line left")
      expect(body).not_to include("type=\"checkbox\"", "capture 1")
    end

    it "leaves out a likely duplicate until the user keeps it" do
      existing = create(:transaction, space: space, account: bank, amount: 2000, transaction_date: Date.new(2026, 11, 2))
      l = line(label: "Picard", existing_transaction: existing, decision: "skipped", flags: [ "already_in_spens" ])
      line(label: "Carrefour")

      get statement_import_path(id: import.id)
      expect(response.body).to include("Already entered on", "on Bank", "Keep it anyway", "Save 1 transaction")

      post keep_statement_import_line_path(statement_import_id: import.id, id: l.id), as: :turbo_stream

      expect(l.reload).to be_included
      expect(response.body).to include("Save 2 transactions")
      expect(response.body).not_to include("Keep it anyway")
    end

    it "leaves out an amount in another currency until it is entered" do
      line(label: "NETFLIX.COM", currency: "USD", amount: -9.99, flags: [ "foreign_currency" ], decision: "skipped")

      get statement_import_path(id: import.id)

      expect(response.body).to include("Amount in USD. Not added until the amount in FCFA is entered.", "Enter the amount", "Nothing to save")
    end

    it "forgets the swipe tip once closed" do
      post dismiss_hint_statement_imports_path
      get statement_import_path(id: import.id)

      expect(user.reload.statement_import_hint_dismissed_at).to be_present
      expect(response.body).not_to include("Swipe a line left")
    end
  end

  describe "editing lines" do
    it "ignores a line by swipe, and brings it back with Add" do
      l = line

      post ignore_statement_import_line_path(statement_import_id: import.id, id: l.id), params: { via: "swipe" }, as: :turbo_stream

      expect(l.reload).to have_attributes(decision: "skipped")
      expect(response.body).to include("removed by you", "Nothing to save")

      post restore_statement_import_line_path(statement_import_id: import.id, id: l.id), as: :turbo_stream

      expect(l.reload).to be_included
    end

    it "ignores a line from the edit sheet too" do
      l = line

      get edit_statement_import_line_path(statement_import_id: import.id, id: l.id)
      expect(response.body).to include("Ignore this line")

      post ignore_statement_import_line_path(statement_import_id: import.id, id: l.id), params: { via: "form" }

      expect(response).to redirect_to(statement_import_path(id: import.id))
      expect(l.reload).to be_removed
    end

    it "closes the edit sheet after Ignore, even when Turbo asks for a stream" do
      l = line

      post ignore_statement_import_line_path(statement_import_id: import.id, id: l.id), params: { via: "form" }, as: :turbo_stream

      expect(response).to redirect_to(statement_import_path(id: import.id))
    end

    it "sets the category in one tap, as the user's choice" do
      l = line(transaction_type_name: nil, category_source: nil)

      patch statement_import_line_path(statement_import_id: import.id, id: l.id), params: { line: { transaction_type_name: "Groceries" } }, as: :turbo_stream

      expect(l.reload).to have_attributes(transaction_type_name: "Groceries", category_source: "user")
    end

    it "edits a line in the usual form, without creating a transaction" do
      l = line(currency: "USD", amount: -9.99, flags: [ "foreign_currency" ], decision: "skipped")

      get edit_statement_import_line_path(statement_import_id: import.id, id: l.id)
      expect(response.body).to include("transaction-form", "Done", "Edit the transaction").and include("Amount read: 9.99")
      expect(response.body).not_to include("phrase-band")

      expect do
        patch statement_import_line_path(statement_import_id: import.id, id: l.id),
              params: { transaction: { kind: "expense", amount: "6000", transaction_type_name: "Groceries", account_name: "Bank",
                                       transaction_date: "2026-11-02", note: "Abonnement famille", label: "Netflix" } }
      end.not_to change(Transaction, :count)

      expect(l.reload).to have_attributes(amount: -6000, currency: "XOF", decision: "pending", category_source: "user")
      expect(l.payload).to include("note" => "Abonnement famille", "label" => "Netflix")
      expect(l.flags).not_to include("foreign_currency")
    end

    it "brings back a line set aside by the reader" do
      l = line(label: "Picard", status: "declined", amount: -615, decision: "skipped")

      post restore_statement_import_line_path(statement_import_id: import.id, id: l.id), as: :turbo_stream

      expect(l.reload).to have_attributes(status: "ok", decision: "pending")
    end
  end

  describe "saving" do
    it "creates every ticked line as a transaction, moves the balance, and shows a toast to undo" do
      line(amount: -2000)
      line(amount: -3000, label: "Picard", fee: 100)
      line(label: "Removed", decision: "skipped", flags: [ "removed" ])

      expect do
        post save_statement_import_path(id: import.id)
      end.to change { space.transactions.count }.by(3) # two lines, one fee

      expect(import.reload.status).to eq("saved")
      expect(import.transactions.count).to eq(3)
      expect(bank.reload.balance).to eq(100_000 - 5100)
      expect(response).to redirect_to(account_path(id: bank.id))
      follow_redirect!
      expect(response.body).to include("2 transactions added", "on the Bank account")
      expect(import.transactions.where(fee_parent_id: nil).pluck(:note)).to contain_exactly("Carrefour", "Picard")
    end

    it "logs each categorised line for the quick-add learners" do
      line(amount: -2000, categorization: { "text" => "2000 Carrefour", "locale" => "en", "proposed" => "Groceries", "draft" => {} })

      expect { post save_statement_import_path(id: import.id) }.to have_enqueued_job(QuickEntry::LearnTransactionJob)

      attempt = QuickEntryAttempt.last
      expect(attempt).to have_attributes(source: "statement_import", text: "2000 Carrefour", ai_used: false)
      expect(attempt.rules_draft["transaction_type_name"]).to eq("Groceries")
    end

    it "reports how saved lines got their category, so we can see whether Other gets fixed" do
      line(category_source: "rules")
      line(category_source: "fallback", transaction_type_name: "Groceries", categorization: { "proposed" => nil, "draft" => {} })
      line(category_source: "user", categorization: { "proposed" => nil, "draft" => {} })

      result = StatementImports::Save.call(import)

      expect(result.categories).to include("category_rules" => 1, "category_fallback" => 1, "category_user" => 1,
                                           "category_user_from_fallback" => 1)
    end

    it "saves nothing while a ticked line is incomplete" do
      line
      line(transaction_type_name: nil, category_source: nil)

      expect { post save_statement_import_path(id: import.id) }.not_to change(Transaction, :count)

      expect(import.reload.status).to eq("ready")
      expect(flash[:alert]).to include("1 ticked line is incomplete")
    end

    it "undoes the whole import, balance included" do
      line(amount: -2000)
      post save_statement_import_path(id: import.id)

      post undo_statement_import_path(id: import.id)

      expect(import.reload.status).to eq("undone")
      expect(space.transactions.count).to eq(0)
      expect(bank.reload.balance).to eq(100_000)
    end

    it "no longer undoes an import saved long ago" do
      line(amount: -2000)
      post save_statement_import_path(id: import.id)
      import.update!(saved_at: 1.hour.ago)

      post undo_statement_import_path(id: import.id)

      expect(import.reload.status).to eq("saved")
    end
  end
end
