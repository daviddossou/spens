# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntriesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  describe "GET #new" do
    it "renders the dictation sheet, bare on the dashboard" do
      get new_quick_entry_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("quick_entries.form.title"))
      expect(response.body).to include(I18n.t("quick_entries.form.open_form"))
      expect(response.body).not_to include("quick-entry__pill")
    end

    it "carries the account as a removable context pill" do
      account = create(:account, space: space, name: "NSIA Banque")
      get new_quick_entry_path(account_id: account.id)
      expect(response.body).to include("quick-entry__pill")
      expect(response.body).to include("NSIA Banque")
    end

    it "carries the person, and titles a goal sheet as a deposit" do
      debt = create(:debt, user: user, name: "Mariam", direction: "lent")
      get new_quick_entry_path(debt_id: debt.id)
      expect(response.body).to include("Mariam")

      account = create(:account, space: space, name: "Moto")
      goal = create(:goal, space: space, account: account, name: "Ma première moto", target_amount: 700_000)
      get new_quick_entry_path(goal_id: goal.id)
      expect(response.body).to include(I18n.t("quick_entries.form.title_goal"))
      expect(response.body).to include("Ma première moto")
    end

    it "ignores a context from another space" do
      foreign = create(:account, name: "Autre")
      get new_quick_entry_path(account_id: foreign.id)
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("quick-entry__pill")
    end
  end

  describe "POST #create" do
    it "auto-creates a transaction from a confident utterance" do
      expect do
        post quick_entry_path, params: { text: "2000 zem" }
      end.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.amount.abs).to eq(2000)
      expect(transaction.transaction_type.name).to eq(TransactionTaxonomy.name("moto_taxi", :en))
      expect(response).to have_http_status(:see_other)
    end

    it "falls back to the manual form (no create) when essentials are missing" do
      expect do
        post quick_entry_path,
             params: { text: "groceries" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.not_to(change { space.transactions.count })

      expect(response.body).to include("transaction_form")
    end

    it "links a repayment to an existing debt when the utterance names the person" do
      debt = create(:debt, user: user, name: "Julius", direction: "lent")

      expect do
        post quick_entry_path, params: { text: "received 25000 from Julius on Mobile Money" }
      end.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.debt).to eq(debt)
      expect(transaction.transaction_type.kind).to eq("debt_in")
      expect(transaction.amount.abs).to eq(25_000)
      expect(response).to have_http_status(:see_other)
    end

    it "auto-creates a new debt and links it when lending to an unknown person" do
      expect do
        post quick_entry_path, params: { text: "lent 5000 to John" }
      end.to change { space.transactions.count }.by(1)
        .and change { space.debts.count }.by(1)

      debt = space.debts.order(:created_at).last
      expect(debt.name).to eq("John")
      expect(debt.direction).to eq("lent")

      transaction = space.transactions.order(:created_at).last
      expect(transaction.debt).to eq(debt)
      expect(transaction.transaction_type.kind).to eq("debt_out")
      expect(transaction.amount.abs).to eq(5000)
      expect(response).to have_http_status(:see_other)
    end

    it "records a plain income (no debt link) when the person isn't a known debt" do
      expect do
        post quick_entry_path, params: { text: "received 25000 refund from Sosthene" }
      end.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.debt).to be_nil
      expect(transaction.transaction_type.kind).to eq("income")
    end

    it "routes a transfer to the manual form rather than auto-creating" do
      expect do
        post quick_entry_path,
             params: { text: "transfer 10000 to savings" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.not_to(change { space.transactions.count })
    end

    it "auto-creates a transfer (both legs + fee) when both named accounts exist" do
      create(:account, space: space, name: "Orabank")
      create(:account, space: space, name: "Mobile money")

      expect do
        post quick_entry_path,
             params: { text: "transferred 300000 from Orabank to Mobile money with 700 fee" }
      end.to change { space.transactions.count }.by(3) # transfer in + transfer out + fee

      expect(response).to have_http_status(:see_other)
    end

    it "logs an attempt linked to the transaction on auto-create" do
      expect do
        post quick_entry_path, params: { text: "2000 zem" }
      end.to change(QuickEntryAttempt, :count).by(1)

      attempt = QuickEntryAttempt.order(:created_at).last
      expect(attempt.source).to eq("rules")
      expect(attempt.created_transaction).to eq(space.transactions.order(:created_at).last)
    end

    it "logs a manual-fallback attempt when it can't auto-create" do
      expect do
        post quick_entry_path,
             params: { text: "transfer 10000 to savings" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.to change(QuickEntryAttempt, :count).by(1)

      expect(QuickEntryAttempt.order(:created_at).last.source).to eq("manual_fallback")
    end

    it "uses the AI fallback to fill a category gap, records source ai, and learns a candidate" do
      allow(QuickEntry::LlmParser).to receive(:enabled?).and_return(true)
      llm = instance_double(
        QuickEntry::LlmParser,
        parse: QuickEntry::LlmParser::Result.new(
          kind: "expense", amount: 3000, category_key: "groceries",
          category_name: TransactionTaxonomy.name("groceries", :en), phrase: "ndogou", label: "Ndogou"
        )
      )
      allow(QuickEntry::LlmParser).to receive(:new).and_return(llm)

      expect do
        perform_enqueued_jobs { post quick_entry_path, params: { text: "3000 ndogou" } }
      end.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.label).to eq("Ndogou")     # short title label
      expect(transaction.note).to eq("3000 ndogou") # the raw phrase, verbatim

      attempt = QuickEntryAttempt.order(:created_at).last
      expect(attempt.source).to eq("ai")
      expect(attempt.ai_used).to be(true)
      expect(LearnedAlias.global.find_by(phrase: "ndogou")).to be_candidate
      expect(LearnedAlias.for_space(space).find_by(phrase: "ndogou")).to be_active
    end

    describe "page context" do
      it "defaults the account to the page's when the phrase names none" do
        account = create(:account, space: space, name: "NSIA Banque")

        expect do
          post quick_entry_path, params: { text: "2000 zem", account_id: account.id }
        end.to change { space.transactions.count }.by(1)

        expect(space.transactions.order(:created_at).last.account).to eq(account)
      end

      it "never overrides an account the phrase names" do
        page_account = create(:account, space: space, name: "NSIA Banque")
        named = create(:account, space: space, name: "Wallet")

        post quick_entry_path, params: { text: "2000 zem wallet", account_id: page_account.id }
        expect(space.transactions.order(:created_at).last.account).to eq(named)
      end

      it "links a nameless debt phrase to the page's person (single ongoing debt)" do
        debt = create(:debt, user: user, name: "Mariam", direction: "lent")

        expect do
          post quick_entry_path, params: { text: "received 20000", debt_id: debt.id }
        end.to change { space.transactions.count }.by(1)

        transaction = space.transactions.order(:created_at).last
        expect(transaction.debt).to eq(debt)
        expect(transaction.transaction_type.kind).to eq("debt_in")
      end

      it "auto-creates a deposit (transfer into the goal's account) when the phrase names the source" do
        from = create(:account, space: space, name: "MTN Mobile Money")
        target = create(:account, space: space, name: "Moto")
        goal = create(:goal, space: space, account: target, name: "Ma première moto", target_amount: 700_000)

        expect do
          post quick_entry_path, params: { text: "transfer 25000 from MTN Mobile Money", goal_id: goal.id }
        end.to change { space.transactions.count }.by(2) # both legs

        legs = space.transactions.order(:created_at).last(2)
        expect(legs.map { |l| l.account.name }).to contain_exactly("MTN Mobile Money", "Moto")
      end
    end

    it "requires authentication" do
      sign_out user
      post quick_entry_path, params: { text: "2000 zem" }
      expect(response).to have_http_status(:redirect)
    end
  end
end
