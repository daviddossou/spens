# frozen_string_literal: true

# A person seen as one relation, not two folders. Aggregates the ongoing lent and
# borrowed debts sharing a name into a single view: the net balance and its side,
# the two gross sub-totals, and a merged timeline. No table of its own — it's
# derived from the Debt records (unique per name + direction while ongoing).
class DebtRelation
  attr_reader :space, :name, :lent, :borrowed

  def initialize(space:, name:, debts: nil)
    @space = space
    @name = name
    scope = debts || space.debts.ongoing.where(name: name)
    @lent = scope.find(&:lent?)
    @borrowed = scope.find(&:borrowed?)
  end

  # The relation a given debt belongs to (both directions of its person). A
  # closed debt (settled or written off) is out of the ongoing scope, so its
  # page reads as its own single-debt relation — keeping its full history
  # instead of an empty merged timeline.
  def self.for(debt)
    return new(space: debt.space, name: debt.name, debts: [ debt ]) unless debt.ongoing?

    new(space: debt.space, name: debt.name)
  end

  # Every ongoing relation in the space, one per person.
  def self.all_ongoing(space)
    space.debts.ongoing.group_by(&:name).map do |name, debts|
      new(space: space, name: name, debts: debts)
    end
  end

  def owed_to_me
    lent&.remaining_balance.to_f
  end

  def i_owe
    borrowed&.remaining_balance.to_f
  end

  # Net balance: positive means you owe this person, negative means they owe you.
  def net
    i_owe - owed_to_me
  end

  def net_amount
    net.abs
  end

  # Which side the net lands on — mirrors Debt#direction so the same colours,
  # labels and sections apply.
  def net_direction
    net >= 0 ? "borrowed" : "lent"
  end

  # A real two-way relation: money flows both ways and neither side is settled.
  def two_way?
    owed_to_me.positive? && i_owe.positive?
  end

  def debts
    [ lent, borrowed ].compact
  end

  # Up to two initials for the avatar.
  def initials
    name.to_s.split(/\s+/).first(2).map { |w| w[0] }.join.upcase
  end

  # A one-directional relation (or one side settled) reads like a plain debt.
  def single?
    !two_way?
  end

  # The debt to act on by default (edit, add a movement) — the net side's record.
  def primary_debt
    net_direction == "borrowed" ? (borrowed || lent) : (lent || borrowed)
  end

  # Merged history across both directions, for the unified timeline.
  def transactions
    space.transactions.where(debt_id: debts.map(&:id))
  end

  # The amount a "Compenser" would offset — the smaller of the two sides.
  def offsettable
    [ owed_to_me, i_owe ].min
  end

  # The repayment intent to preselect on a person's page: repaying what you owe
  # (debt_out) when the net is against you, receiving a repayment (debt_in) when
  # it's in your favour.
  def repayment_kind
    net_direction == "borrowed" ? "debt_out" : "debt_in"
  end

  def repayment_direction
    net_direction
  end
end
