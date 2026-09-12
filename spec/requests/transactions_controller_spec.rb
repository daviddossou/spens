# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #new" do
    context "when requesting HTML format" do
      it "returns a successful response" do
        get new_transaction_path
        expect(response).to have_http_status(:success)
      end

      it "accepts kind parameter" do
        get new_transaction_path(kind: 'income')
        expect(response).to have_http_status(:success)
      end

      it "accepts account_id parameter" do
        account = create(:account, user: user, name: "Savings Account")
        get new_transaction_path(account_id: account.id)
        expect(response).to have_http_status(:success)
      end

      it "renders the person-first debt category" do
        create(:debt, user: user, name: "Alice", direction: "lent")
        get new_transaction_path(kind: 'debt_out')
        expect(response).to have_http_status(:success)
        expect(response.body).to include('debt-fields')
        expect(response.body).to include(I18n.t('transactions.form.contact_name_label'))
      end
    end

    context "when requesting turbo_stream format" do
      it "returns a successful response" do
        get new_transaction_path(kind: 'income'), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('turbo-stream')
      end

      it "renders the form partial" do
        get new_transaction_path(kind: 'income'), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.body).to include('turbo-stream')
        expect(response.body).to include('transaction_form')
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get new_transaction_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        kind: 'expense',
        account_name: 'Cash',
        transaction_type_name: 'Groceries',
        amount: 100.50,
        transaction_date: Date.current,
        note: 'Weekly shopping'
      }
    end

    let(:invalid_attributes) do
      {
        kind: 'expense',
        account_name: '',
        transaction_type_name: 'Groceries',
        amount: -10,
        transaction_date: Date.current
      }
    end

    context "when completing a quick-entry fallback" do
      it "links the attempt to the created transaction and learns from the picked category" do
        attempt = create(:quick_entry_attempt, user: user, text: "achat de zoomzoom 100",
                                               locale: "fr",
                                               source: "manual_fallback",
                                               rules_draft: { "kind" => "expense", "amount" => 100.5,
                                                              "transaction_date" => Date.current.iso8601 })

        perform_enqueued_jobs do
          post transactions_path, params: {
            transaction: valid_attributes.merge(quick_entry_attempt_id: attempt.id,
                                                transaction_type_name: TransactionTaxonomy.name("groceries", :en))
          }
        end

        attempt.reload
        expect(attempt.transaction_id).to be_present
        expect(attempt.outcome).to eq("edited")
        expect(LearnedAlias.find_by(phrase: "zoomzoom")&.taxonomy_key).to eq("groceries")
      end

      it "ignores an attempt id from another space" do
        other = create(:quick_entry_attempt)

        post transactions_path, params: { transaction: valid_attributes.merge(quick_entry_attempt_id: other.id) }

        expect(other.reload.transaction_id).to be_nil
        expect(response).to have_http_status(:see_other)
      end
    end

    context "with valid parameters" do
      it "creates a new transaction" do
        expect {
          post transactions_path, params: { transaction: valid_attributes }
        }.to change(Transaction, :count).by(1)
      end

      it "redirects to the transaction detail" do
        post transactions_path, params: { transaction: valid_attributes }
        created_transaction = Transaction.order(created_at: :desc).first
        expect(response).to redirect_to("#{transaction_path(id: created_transaction.id)}?format=html")
      end

      it "sets a success notice" do
        post transactions_path, params: { transaction: valid_attributes }
        expect(flash[:notice]).to eq(I18n.t('transactions.create.success'))
      end

      context "with transfer kind" do
        let(:transfer_attributes) do
          {
            kind: 'transfer',
            from_account_name: 'Bank',
            to_account_name: 'Cash',
            amount: 200.00,
            transaction_date: Date.current
          }
        end

        it "creates two transactions" do
          expect {
            post transactions_path, params: { transaction: transfer_attributes }
          }.to change(Transaction, :count).by(2)
        end

        it "redirects with success notice" do
          post transactions_path, params: { transaction: transfer_attributes }
          expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
          expect(flash[:notice]).to be_present
        end
      end

      context "with debt kind from the main form" do
        let(:space) { user.spaces.first }

        it "creates a debt and a debt_out transaction for a brand-new lent person" do
          expect {
            post transactions_path, params: { transaction: {
              kind: 'debt_out', contact_name: 'Carol', direction: 'lent',
              amount: 75, transaction_date: Date.current
            } }
          }.to change(Transaction, :count).by(1).and change(Debt, :count).by(1)

          debt = space.debts.find_by(name: 'Carol')
          expect(debt.direction).to eq('lent')
          expect(debt.total_lent).to eq(75)
        end

        it "creates a debt_in transaction for a brand-new borrowed person" do
          post transactions_path, params: { transaction: {
            kind: 'debt_in', contact_name: 'Dan', direction: 'borrowed',
            amount: 200, transaction_date: Date.current
          } }

          debt = space.debts.find_by(name: 'Dan', direction: 'borrowed')
          expect(debt.total_lent).to eq(200)
        end

        it "reuses an existing debt for the same person and direction" do
          existing = create(:debt, user: user, name: 'Alice', direction: 'lent')

          expect {
            post transactions_path, params: { transaction: {
              kind: 'debt_in', contact_name: 'Alice', direction: 'lent',
              amount: 20, transaction_date: Date.current
            } }
          }.to change(Transaction, :count).by(1).and change(Debt, :count).by(0)

          expect(existing.reload.total_reimbursed).to eq(20)
        end

        it "fails without a person" do
          expect {
            post transactions_path, params: { transaction: {
              kind: 'debt_out', contact_name: '', direction: 'lent', amount: 50
            } }
          }.not_to change(Transaction, :count)
        end

        it "fails without a direction for a new person" do
          expect {
            post transactions_path, params: { transaction: {
              kind: 'debt_out', contact_name: 'Eve', direction: '', amount: 50
            } }
          }.not_to change(Transaction, :count)
        end
      end

      context "with optional fields" do
        let(:attributes_with_date) do
          valid_attributes.merge(transaction_date: 1.week.ago.to_date)
        end

        it "accepts custom transaction date" do
          post transactions_path, params: { transaction: attributes_with_date }
          expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        end

        it "accepts note field" do
          post transactions_path, params: { transaction: valid_attributes.merge(note: 'Test note') }
          expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        end

        it "accepts description field" do
          post transactions_path, params: { transaction: valid_attributes.merge(description: 'Custom description') }
          expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        end

        it "stores a typed note as the human text, keeping the system description" do
          expect {
            post transactions_path, params: { transaction: valid_attributes.merge(note: 'My groceries') }
          }.to change(Transaction, :count).by(1)
          txn = Transaction.order(created_at: :desc).first
          expect(txn.note).to eq('My groceries')
          expect(txn.description).to eq('Groceries')
        end

        it "uses auto-generated description when description is blank" do
          expect {
            post transactions_path, params: { transaction: valid_attributes.merge(description: '') }
          }.to change(Transaction, :count).by(1)
          expect(Transaction.order(created_at: :desc).first.description).to eq('Groceries')
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a transaction" do
        expect {
          post transactions_path, params: { transaction: invalid_attributes }
        }.not_to change(Transaction, :count)
      end

      it "returns unprocessable entity status" do
        post transactions_path, params: { transaction: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "missing required fields" do
        it "fails without amount" do
          attributes = valid_attributes.dup
          attributes.delete(:amount)

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "succeeds without account_name for expense" do
          attributes = valid_attributes.merge(account_name: '')

          expect {
            post transactions_path, params: { transaction: attributes }
          }.to change(Transaction, :count).by(1)
        end

        it "fails without transaction_type_name for expense" do
          attributes = valid_attributes.merge(transaction_type_name: '')

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end
      end

      context "transfer validations" do
        it "fails without from_account_name" do
          attributes = {
            kind: 'transfer',
            to_account_name: 'Cash',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails without to_account_name" do
          attributes = {
            kind: 'transfer',
            from_account_name: 'Bank',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails with same from and to accounts" do
          attributes = {
            kind: 'transfer',
            from_account_name: 'Cash',
            to_account_name: 'Cash',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        post transactions_path, params: { transaction: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a transaction" do
        sign_out user
        expect {
          post transactions_path, params: { transaction: valid_attributes }
        }.not_to change(Transaction, :count)
      end
    end
  end

  describe "parameter handling" do
    it "permits all required parameters" do
      params = {
        transaction: {
          kind: 'expense',
          account_name: 'Cash',
          from_account_name: 'Bank',
          to_account_name: 'Cash',
          amount: 100,
          transaction_date: Date.current,
          transaction_type_name: 'Food',
          note: 'Test note',
          description: 'Custom description',
          unpermitted_param: 'should be filtered'
        }
      }

      post transactions_path, params: params
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "edge cases" do
    let(:base_attributes) do
      {
        kind: 'expense',
        account_name: 'Test Account',
        transaction_type_name: 'Groceries',
        amount: 100.50,
        transaction_date: Date.current
      }
    end

    context "with very large amounts" do
      it "handles large decimal values" do
        attributes = base_attributes.merge(amount: 999_999_999.99)
        post transactions_path, params: { transaction: attributes }
        expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        expect(flash[:notice]).to be_present
      end
    end

    context "with special characters in fields" do
      it "handles special characters in account names" do
        attributes = base_attributes.merge(account_name: "Spëçîål Àççöunt €$£")
        post transactions_path, params: { transaction: attributes }
        expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        expect(flash[:notice]).to be_present
      end

      it "handles special characters in notes" do
        attributes = base_attributes.merge(note: "Emoji test 🎉💰📈 and symbols @#$%")
        post transactions_path, params: { transaction: attributes }
        expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        expect(flash[:notice]).to be_present
      end
    end

    context "with future dates" do
      it "accepts future transaction dates" do
        attributes = base_attributes.merge(transaction_date: 1.week.from_now.to_date)
        post transactions_path, params: { transaction: attributes }
        expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        expect(flash[:notice]).to be_present
      end
    end

    context "with decimal precision" do
      it "handles amounts with many decimal places" do
        attributes = base_attributes.merge(amount: 100.123456)
        post transactions_path, params: { transaction: attributes }
        expect(response.location).to match(%r{/transactions/[^?]+\?format=html})
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "GET #show" do
    let(:account) { create(:account, user: user, name: "Cash") }
    let(:transaction_type) { create(:transaction_type, user: user, kind: :expense, name: "Groceries") }
    let(:transaction) do
      create(:transaction, user: user, account: account, transaction_type: transaction_type, amount: -42.50)
    end

    it "links the hero amount to the edit form" do
      get transaction_path(id: transaction.id)

      expect(response.body).to match(/<a [^>]*class="movement-hero__amount[^"]*"[^>]*href="#{Regexp.escape(edit_transaction_path(id: transaction.id))}"|<a [^>]*href="#{Regexp.escape(edit_transaction_path(id: transaction.id))}"[^>]*class="movement-hero__amount/)
    end

    it "renders a FAB opening quick entry on the transaction's account" do
      get transaction_path(id: transaction.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("class=\"fab\"")
      expect(response.body).to include(new_transaction_path(account_id: account.id))
    end
  end

  describe "GET #edit" do
    let(:account) { create(:account, user: user, name: "Cash") }
    let(:transaction_type) { create(:transaction_type, user: user, kind: :expense, name: "Groceries") }
    let(:transaction) do
      create(:transaction, user: user, account: account, transaction_type: transaction_type,
                           amount: -42.50, description: "Lunch")
    end

    it "returns a successful response" do
      get edit_transaction_path(id: transaction.id)
      expect(response).to have_http_status(:success)
    end

    it "renders kind-switch links scoped to this transaction (id is :id, not :locale)" do
      get edit_transaction_path(id: transaction.id)

      expect(response.body).to include("/transactions/#{transaction.id}/edit?kind=income")
      # The optional (:locale) scope must not swallow the id, doubling the path.
      expect(response.body).not_to match(%r{/#{transaction.id}/transactions/#{transaction.id}/edit})
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get edit_transaction_path(id: transaction.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:account) { create(:account, user: user, name: "Cash") }
    let(:transaction_type) { create(:transaction_type, user: user, kind: :expense, name: "Groceries") }
    let(:transaction) do
      create(:transaction, user: user, account: account, transaction_type: transaction_type,
                           amount: -42.50, description: "Lunch")
    end

    context "correcting a quick-entry transaction's kind (income → expense)" do
      let(:income_type) { create(:transaction_type, user: user, kind: :income, name: "Misc") }
      let(:qe_transaction) do
        create(:transaction, user: user, account: account, transaction_type: income_type,
                             amount: 100, description: "Refund")
      end

      before do
        create(:quick_entry_attempt, user: user, transaction_id: qe_transaction.id,
                                     text: "100 refund", source: "rules",
                                     rules_draft: { "kind" => "income", "amount" => 100,
                                                    "transaction_type_name" => "Misc",
                                                    "transaction_date" => Date.current.iso8601 })
      end

      it "keeps the same transaction id and records the kind correction" do
        perform_enqueued_jobs do
          patch transaction_path(id: qe_transaction.id), params: {
            transaction: { kind: "expense", transaction_type_name: "Groceries", amount: "100" }
          }
        end

        expect(qe_transaction.reload.transaction_type.kind).to eq("expense")

        attempt = QuickEntryAttempt.find_by(transaction_id: qe_transaction.id)
        expect(attempt.outcome).to eq("edited")
        expect(attempt.corrections["kind"]).to eq("from" => "income", "to" => "expense")
      end
    end

    context "with valid parameters" do
      it "updates the transaction description" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { description: "Updated lunch", amount: "42.50" }
        }
        expect(transaction.reload.description).to eq("Updated lunch")
      end

      it "redirects to the transaction show page" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { amount: "50.00" }
        }
        expect(response).to redirect_to("#{transaction_path(id: transaction.id)}?format=html")
      end

      it "sets a success flash" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { amount: "50.00" }
        }
        expect(flash[:notice]).to eq(I18n.t('transactions.update.success'))
      end

      it "updates the transaction amount" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { amount: "75.00" }
        }
        expect(transaction.reload.amount).to eq(-75.00)
      end

      it "updates the transaction category" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { transaction_type_name: "Dining", amount: "42.50" }
        }
        expect(transaction.reload.transaction_type.name).to eq("Dining")
      end

      it "updates the transaction account" do
        new_account = create(:account, user: user, name: "Bank")
        patch transaction_path(id: transaction.id), params: {
          transaction: { account_name: "Bank" }
        }
        expect(transaction.reload.account).to eq(new_account)
      end

      it "keeps the same account when account_name matches current" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { account_name: "Cash" }
        }
        expect(transaction.reload.account).to eq(account)
      end

      it "keeps the existing account when account_name is not submitted" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { description: "Just a desc change" }
        }
        expect(transaction.reload.account).to eq(account)
      end

      it "updates the transaction date" do
        new_date = 3.days.ago.to_date
        patch transaction_path(id: transaction.id), params: {
          transaction: { transaction_date: new_date }
        }
        expect(transaction.reload.transaction_date).to eq(new_date)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        patch transaction_path(id: transaction.id), params: {
          transaction: { description: "Nope" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

# The phrase field: GET #new parses it (rules only) to prefill the form; hand-set fields
# travel as locked[...] and win; POST #create with the phrase logs the attempt.
RSpec.describe "Transactions phrase fill", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  describe "GET #new with a phrase" do
    it "prefills amount, category and account from the phrase and marks them as read" do
      create(:account, space: space, name: "Wallet")

      get new_transaction_path(text: "2000 zem yesterday wallet")

      expect(response).to have_http_status(:success)
      expect(response.body).to include('value="2000"')
      expect(response.body).to include(TransactionTaxonomy.name("moto_taxi", :en))
      expect(response.body).to include('value="Wallet"')
      expect(response.body).to include("transaction-form__amount is-filled")
      expect(response.body).to include("data-phrase-filled-count=\"")
      expect(response.body).to include("More details · date: yesterday")
    end

    it "keeps a hand-set field over what the phrase says" do
      create(:account, space: space, name: "Wallet")
      create(:account, space: space, name: "Bank")

      get new_transaction_path(text: "2000 zem wallet", locked: { account_name: "Bank", amount: "2500" })

      expect(response.body).to include('value="Bank"')
      expect(response.body).to include('value="2500"')
      expect(response.body).not_to include("transaction-form__amount is-filled")
    end

    it "lets a locked kind survive a reload while the phrase still fills the rest" do
      get new_transaction_path(kind: "income", text: "2000 zem", locked: { kind: "income" })

      expect(response.body).to include('value="income"')
      expect(response.body).to include('value="2000"')
    end

    it "defaults the account to the page's when the phrase names none" do
      account = create(:account, space: space, name: "NSIA Banque")

      get new_transaction_path(text: "2000 zem", account_id: account.id)

      expect(response.body).to include('value="NSIA Banque"')
    end

    it "drops a parsed expense category when the user locked the kind to income" do
      get new_transaction_path(kind: "income", text: "2000 zem", locked: { kind: "income" })

      expect(response.body).not_to include(TransactionTaxonomy.name("moto_taxi", :en))
      expect(response.body).to include('value="2000"')
    end

    it "opens as a deposit from a goal and reads the source account from the phrase" do
      goal_account = create(:account, space: space, name: "Zanzibar")
      create(:account, space: space, name: "MTN")

      get new_transaction_path(kind: "transfer", account_id: goal_account.id, text: "25k from MTN")

      expect(response.body).to include('value="MTN"')
      expect(response.body).to include('value="Zanzibar"')
      expect(response.body).to include('value="25000"')
    end

    it "opens locked on a person and keeps the debt kind for a nameless phrase" do
      create(:debt, user: user, name: "Mariam", direction: "lent")

      get new_transaction_path(kind: "debt_out", contact_name: "Mariam", person_locked: 1, text: "20k")

      expect(response).to have_http_status(:success)
      expect(response.body).to include('value="20000"')
      expect(response.body).to include('value="Mariam"')
    end

    context "with the AI pass" do
      let(:llm_result) do
        QuickEntry::LlmParser::Result.new(
          kind: "income", amount: 45_000, category_key: "gift_received",
          category_name: TransactionTaxonomy.name("gift_received", :en), phrase: "from parents", label: "From parents"
        )
      end

      before do
        allow(QuickEntry::LlmParser).to receive(:enabled?).and_return(true)
        allow(QuickEntry::LlmParser).to receive(:new).and_return(instance_double(QuickEntry::LlmParser, parse: llm_result))
      end

      it "flags a rules-only pass that left gaps so the sheet asks for the AI" do
        get new_transaction_path(text: "received 45000 from parents")

        expect(response.body).to include('data-phrase-needs-ai="true"')
        expect(QuickEntry::LlmParser).not_to have_received(:new)
      end

      it "does not ask for the AI on a phrase without an amount or a second word" do
        get new_transaction_path(text: "A")
        expect(response.body).to include('data-phrase-needs-ai="false"')

        get new_transaction_path(text: "45000")
        expect(response.body).to include('data-phrase-needs-ai="false"')
      end

      it "does not ask for the AI when the rules were confident" do
        get new_transaction_path(text: "2000 zem")

        expect(response.body).to include('data-phrase-needs-ai="false"')
      end

      it "lets the AI decide the kind, category and label, and carries the logged attempt" do
        get new_transaction_path(text: "received 45000 from parents", ai: "1")

        expect(response.body).to include('value="income"')
        expect(response.body).to include(TransactionTaxonomy.name("gift_received", :en))
        expect(response.body).to include('value="From parents"')
        attempt = QuickEntryAttempt.order(:created_at).last
        expect(attempt.ai_used).to be(true)
        expect(response.body).to include(attempt.id)
        expect(response.body).to include('data-phrase-needs-ai="false"')
      end

      it "links the live attempt on save instead of logging a second one" do
        get new_transaction_path(text: "received 45000 from parents", ai: "1")
        attempt = QuickEntryAttempt.order(:created_at).last

        expect do
          post transactions_path, params: {
            text: "received 45000 from parents",
            transaction: { kind: "income", amount: 45_000, quick_entry_attempt_id: attempt.id,
                           transaction_type_name: TransactionTaxonomy.name("gift_received", :en),
                           note: "received 45000 from parents", transaction_date: Date.current }
          }
        end.not_to change { QuickEntryAttempt.count }

        expect(attempt.reload.transaction_id).to eq(space.transactions.order(:created_at).last.id)
        expect(attempt.source).to eq("ai")
      end
    end

    it "asks which amount when the phrase holds several and nothing settles it" do
      get new_transaction_path(text: "25 balls of attieke 10 each")

      expect(response.body).to include('value="25"')
      expect(response.body).to include("amount-candidates")
      expect(response.body).to include('data-amount="25"')
      expect(response.body).to include('data-amount="10"')
      expect(response.body).not_to include("transaction-form__amount is-filled")
    end

    it "renders the phrase field once, outside the form frame, posting with the form" do
      get new_transaction_path

      expect(response.body).to include('id="phrase"')
      expect(response.body).to include('form="transaction-form"')
      expect(response.body.scan("phrase-band__input").size).to eq(1)
      # The mic ships hidden: only a browser exposing speech recognition reveals it.
      expect(response.body).to match(/class="phrase-band__mic" hidden/)

      # The Android app's WebView declares the API but can't run it: no mic at all there.
      get new_transaction_path, headers: { "User-Agent" => "Turbo Native Android Mozilla/5.0 (Linux; Android 14; wv)" }
      expect(response.body).not_to include("phrase-band__mic")
      # A hover prefetch of a kind card would otherwise read as a manual kind choice.
      expect(response.body).to include('data-turbo-prefetch="false"')
    end
  end

  describe "POST #create with a phrase" do
    let(:account) { create(:account, space: space, name: "Wallet") }
    let(:category) { TransactionTaxonomy.name("moto_taxi", :en) }

    def submit(text:, **fields)
      post transactions_path, params: {
        text: text,
        transaction: { kind: "expense", amount: 2000, transaction_type_name: category,
                       account_name: account.name, note: text, transaction_date: Date.current }.merge(fields)
      }
    end

    it "creates the transaction, keeps the phrase as the note and logs a linked attempt" do
      expect { submit(text: "2000 zem wallet") }.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.note).to eq("2000 zem wallet")
      expect(transaction.account).to eq(account)
      attempt = QuickEntryAttempt.order(:created_at).last
      expect(attempt.text).to eq("2000 zem wallet")
      expect(attempt.transaction_id).to eq(transaction.id)
      expect(attempt.ai_used).to be(false)
      expect(response).to have_http_status(:see_other)
    end

    it "asks the AI for a category only when the form is submitted without one" do
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
        perform_enqueued_jobs { submit(text: "3000 ndogou", amount: 3000, transaction_type_name: "") }
      end.to change { space.transactions.count }.by(1)

      transaction = space.transactions.order(:created_at).last
      expect(transaction.transaction_type.name).to eq(TransactionTaxonomy.name("groceries", :en))
      expect(transaction.label).to eq("Ndogou")
      expect(QuickEntryAttempt.order(:created_at).last.ai_used).to be(true)
    end

    it "learns from a category corrected in the form before the first save" do
      groceries = TransactionTaxonomy.name("groceries", :en)

      perform_enqueued_jobs { submit(text: "2000 zem", transaction_type_name: groceries) }

      attempt = QuickEntryAttempt.order(:created_at).last
      expect(attempt.outcome).to eq("edited")
      expect(attempt.corrections["transaction_type_name"]).to include("from" => category, "to" => groceries)
      expect(LearnedAlias.for_space(space).find_by(phrase: "zem")&.taxonomy_key).to eq("groceries")
    end

    it "never consults the AI when the category is already chosen" do
      allow(QuickEntry::LlmParser).to receive(:enabled?).and_return(true)
      expect(QuickEntry::LlmParser).not_to receive(:new)

      submit(text: "2000 zem")
      expect(response).to have_http_status(:see_other)
    end

    it "re-renders the sheet with the phrase kept when the form is invalid" do
      submit(text: "zem wallet", amount: "")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('value="zem wallet"')
    end
  end
end
