# frozen_string_literal: true

# Usage: rails runner db/seeds/sample_transactions.rb
# Or:   rails runner "load 'db/seeds/sample_transactions.rb'"
#
# Safe to run multiple times — skips if transactions already exist for the period.
# NEVER runs in production.

abort "🚫 This seed cannot be run in production!" if Rails.env.production?

EMAIL      = "daviddossou@gmail.com"
SPACE_NAME = "Personal"
COUNT      = 50

user = User.find_by(email: EMAIL)
abort "❌ User #{EMAIL} not found. Sign up first." unless user

space = user.spaces.find_by(name: SPACE_NAME)
abort "❌ Space '#{SPACE_NAME}' not found for #{EMAIL}." unless space

# --- Accounts ---
accounts = {}
%w[Cash Bank Mobile\ Money].each do |name|
  accounts[name] = space.accounts.find_or_create_by!(name: name)
end

# --- Debts ---
debts = {}
[
  { name: "Alex", direction: "lent" },
  { name: "Sophie", direction: "borrowed" }
].each do |d|
  debts[d[:name]] = space.debts.find_or_create_by!(name: d[:name], direction: d[:direction])
end

# --- Transaction definitions ---
EXPENSE_CATEGORIES = [
  { name: "Groceries",      amount_range: 500..8000 },
  { name: "Dining Out",     amount_range: 8000..45000 },
  { name: "Transport",      amount_range: 200..3000 },
  { name: "Rent",           amount_range: 30000..60000 },
  { name: "Electricity",    amount_range: 2000..8000 },
  { name: "Internet",       amount_range: 1500..4000 },
  { name: "Entertainment",  amount_range: 500..5000 },
  { name: "Clothing",       amount_range: 1500..12000 },
  { name: "Medical",        amount_range: 1000..10000 },
  { name: "Subscriptions",  amount_range: 5000..20000 }
].freeze

INCOME_CATEGORIES = [
  { name: "Salary",         amount_range: 150000..3000000 },
  { name: "Freelance",      amount_range: 10000..800000 },
  { name: "Side Hustle",    amount_range: 50000..3000000 },
  { name: "Gift Received",  amount_range: 20000..2000000 }
].freeze

DESCRIPTIONS = {
  "Groceries"     => [ "Weekly groceries", "Quick market run", "Fruit & veggies", "Supermarket haul" ],
  "Dining Out"    => [ "Lunch with friends", "Coffee & pastry", "Dinner date", "Street food" ],
  "Transport"     => [ "Uber ride", "Bus fare", "Fuel top-up", "Taxi to work" ],
  "Rent"          => [ "Monthly rent" ],
  "Electricity"   => [ "Electric bill", "Utility payment" ],
  "Internet"      => [ "Internet bill", "Mobile data top-up" ],
  "Entertainment" => [ "Movie night", "Concert ticket", "Streaming service", "Board game café" ],
  "Clothing"      => [ "New shoes", "T-shirt haul", "Winter jacket", "Work outfit" ],
  "Medical"       => [ "Pharmacy run", "Doctor visit", "Lab tests" ],
  "Subscriptions" => [ "Spotify", "Netflix", "Cloud storage", "Gym membership" ],
  "Salary"        => [ "Monthly salary" ],
  "Freelance"     => [ "Client project", "Design gig", "Consulting fee" ],
  "Side Hustle"   => [ "Online sales", "Tutoring session" ],
  "Gift Received" => [ "Birthday money", "Family gift" ]
}.freeze

# --- Helper to find or create transaction types (case-insensitive) ---
def find_or_create_type(space, name, kind)
  existing = space.transaction_types.where(kind: kind).where("LOWER(name) = ?", name.downcase.strip).first
  existing || space.transaction_types.create!(name: name.strip, kind: kind, budget_goal: 0.0)
end

# --- Generate transactions ---
created = 0

ActiveRecord::Base.transaction do
  COUNT.times do |i|
    date = Date.current - rand(1..90)
    roll = rand(100)

    if roll < 55 # 55% expenses
      cat = EXPENSE_CATEGORIES.sample
      type = find_or_create_type(space, cat[:name], "expense")
      amount = rand(cat[:amount_range])
      desc = DESCRIPTIONS[cat[:name]]&.sample || cat[:name]
      account = accounts.values.sample

      CreateTransactionService.new(
        space: space,
        account: account,
        transaction_type: type,
        amount: amount,
        transaction_date: date,
        description: desc
      ).call

    elsif roll < 75 # 20% income
      cat = INCOME_CATEGORIES.sample
      type = find_or_create_type(space, cat[:name], "income")
      amount = rand(cat[:amount_range])
      desc = DESCRIPTIONS[cat[:name]]&.sample || cat[:name]
      account = accounts.values.sample

      CreateTransactionService.new(
        space: space,
        account: account,
        transaction_type: type,
        amount: amount,
        transaction_date: date,
        description: desc
      ).call

    elsif roll < 90 # 15% transfers
      from_acc, to_acc = accounts.values.sample(2)
      amount = rand(5000..50000)

      type_out = find_or_create_type(space, "📤 Transfer out", "transfer_out")
      CreateTransactionService.new(
        space: space,
        account: from_acc,
        transaction_type: type_out,
        amount: amount,
        transaction_date: date,
        description: "#{from_acc.name} ➡️ #{to_acc.name}"
      ).call

      type_in = find_or_create_type(space, "📥 Transfer in", "transfer_in")
      CreateTransactionService.new(
        space: space,
        account: to_acc,
        transaction_type: type_in,
        amount: amount,
        transaction_date: date,
        description: "#{to_acc.name} ⬅️ #{from_acc.name}"
      ).call

    else # 10% debt transactions
      debt = debts.values.sample
      account = accounts.values.sample
      amount = rand(20000..300000)

      if debt.lent?
        kind = %w[debt_out debt_in].sample
        type_name = kind == "debt_out" ? "Money Lent" : "Repayment Received"
      else
        kind = %w[debt_in debt_out].sample
        type_name = kind == "debt_in" ? "Money Borrowed" : "Loan Repayment"
      end

      type = find_or_create_type(space, type_name, kind)

      CreateTransactionService.new(
        space: space,
        account: account,
        transaction_type: type,
        amount: amount,
        transaction_date: date,
        description: "#{type_name} — #{debt.name}",
        debt: debt
      ).call
    end

    created += 1
  end
end

puts "✅ Created #{created} sample transactions in '#{SPACE_NAME}' for #{EMAIL}."
