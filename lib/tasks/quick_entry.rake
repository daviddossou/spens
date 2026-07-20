# frozen_string_literal: true

# QuickEntry challenge harness — feeds a curated corpus of West-African (francophone)
# transaction utterances through the deterministic rules brain (QuickEntry::Parser),
# WITHOUT creating anything, then reports what parses cleanly vs what slips through.
#
# Two banks:
#   • regression — vocabulary the parser already supports. Validates the recent overhaul;
#                  any ⚠ here is a regression to investigate.
#   • challenge  — authentic slang / phrasing it likely misses (researched from how people
#                  actually talk across BJ/CI/SN/TG/ML/BF/NE/GN). Every ⚠ is a candidate
#                  dictionary addition for an admin to eyeball and validate.
#
# Read-only: nothing is written to the space. Run it, scan the ⚠ rows, validate the ones
# worth supporting, then widen config/quick_entry_keywords.yml or
# config/transaction_type_aliases.yml (or fix QuickEntry::Parser for the :logic gaps).
#
# Usage:
#   bin/rails quick_entry:challenge
#   bin/rails "quick_entry:challenge[<space_id>]"
namespace :quick_entry do
  desc "Challenge QuickEntry with West-African francophone phrases (read-only diagnostic)"
  task :challenge, [ :space_id ] => :environment do |_t, args|
    QuickEntryChallenge.run(args[:space_id].presence)
  end

  # Turns the kind corrections users make (recorded on QuickEntryAttempt) into candidate keywords
  # for the admin review queue. Pass "dry" to preview without writing or stamping anything:
  #   bin/rails quick_entry:mine
  #   bin/rails "quick_entry:mine[dry]"
  desc "Mine candidate kind-keywords from real corrections into the admin review queue"
  task :mine, [ :mode ] => :environment do |_t, args|
    dry = %w[dry preview dry_run].include?(args[:mode].to_s.downcase)
    QuickEntryMineReport.run(dry: dry)
  end

  # Re-runs the (hardened) built-in check over pending candidates and rejects the redundant
  # ones — one-off cleanup after widening the dedup rules:
  #   bin/rails quick_entry:prune_redundant_candidates
  desc "Reject candidate aliases/keywords the built-in dictionaries already cover"
  task prune_redundant_candidates: :environment do
    [ LearnedAlias, LearnedKeyword ].each do |model|
      pruned = model.candidate.select { |row| model.send(:built_in?, row.phrase) }
      pruned.each(&:reject!)
      puts "#{model.name}: rejected #{pruned.size} redundant candidate(s)"
    end
  end

  module QuickEntryMineReport
    module_function

    def run(dry:)
      result = QuickEntry::Miner.run(dry_run: dry)

      puts ""
      puts dry ? "QuickEntry miner · DRY RUN (nothing written)" : "QuickEntry miner"
      if result.candidates.empty?
        puts "  no new kind-keyword candidates from #{result.scanned} edited attempt(s)"
      else
        verb = dry ? "would teach" : "taught (candidate)"
        result.candidates.each do |c|
          puts "  • #{c.phrase.ljust(24)} → #{c.kind.ljust(10)} #{verb}   [#{c.text}]"
        end
        puts ""
        puts "  #{result.candidates.size} candidate(s) from #{result.scanned} edited attempt(s)" \
             "#{dry ? '' : ' · review at /admin/learned_keywords'}"
      end
      puts ""
    end
  end

  module QuickEntryChallenge
    module_function

    DEFAULT_SPACE_ID = "2d0f4510-ffc1-4d05-ba4e-a3e8f9d4bab2"

    FIX_LABELS = {
      alias:   "config/transaction_type_aliases.yml — category synonyms (merchant/dish/mode)",
      keyword: "config/quick_entry_keywords.yml — kind verbs / mobile-money instruments",
      number:  "config/quick_entry_keywords.yml → numbers — amount words & local multipliers",
      logic:   "QuickEntry::Parser — a parsing-logic gap, not just a missing word"
    }.freeze

    def run(space_id)
      id = space_id || DEFAULT_SPACE_ID
      space = Space.find_by(id: id)
      abort("No space with id #{id.inspect}. Pass a valid space id as an argument.") unless space

      results = corpus.map { |c| evaluate(c, space) }

      puts banner(space, id)
      %i[regression challenge].each do |bank|
        rows = results.select { |r| r[:case][:bank] == bank }
        next if rows.empty?

        puts section_header(bank, rows)
        rows.each { |r| print_row(r) }
      end

      print_summary(results)
      print_suggestions(results)
    end

    # --- evaluation ---------------------------------------------------------

    def evaluate(kase, space)
      draft = QuickEntry::Parser.parse(kase[:text], space: space, locale: kase[:locale])
      exp = kase[:expect] || {}
      expected_category = exp[:category] && (TransactionTaxonomy.name(exp[:category], kase[:locale]) || exp[:category])

      reasons = []
      reasons << "amount"   if exp[:amount]   && draft.amount != exp[:amount]
      reasons << "kind"     if exp[:kind]     && draft.kind != exp[:kind]
      reasons << "category" if exp[:category] && draft.transaction_type_name != expected_category

      { case: kase, draft: draft, status: reasons.empty? ? :ok : :review, reasons: reasons }
    end

    # --- printing -----------------------------------------------------------

    def banner(space, id)
      [
        "",
        bold("QuickEntry challenge  ·  #{space.name} (#{space.currency})"),
        dim("space #{id} · #{space.accounts.count} account(s) · read-only, nothing is created"),
        ""
      ].join("\n")
    end

    def section_header(bank, rows)
      pass = rows.count { |r| r[:status] == :ok }
      title =
        if bank == :regression
          "RECENT-FEATURE REGRESSION — should all parse (#{pass}/#{rows.size} ok)"
        else
          "CHALLENGE / NEW VOCABULARY — ⚠ = gap to validate (#{rows.size - pass} of #{rows.size} miss today)"
        end
      "\n#{bold(title)}"
    end

    def print_row(r)
      kase = r[:case]
      mark = r[:status] == :ok ? green("✓") : yellow("⚠")
      text = kase[:text].length > 40 ? "#{kase[:text][0, 39]}…" : kase[:text].ljust(40)

      puts "  #{mark}  #{text} → #{summarize(r[:draft])}#{region(kase)}"
      puts "        #{dim("expected: #{expectation(kase)}")}" unless r[:reasons].empty?
      puts "        #{dim("↳ #{kase[:suggest]}")}" if kase[:suggest] && r[:status] == :review
    end

    def summarize(d)
      parts = [ d.kind, fmt(d.amount) ]
      parts << (d.kind == "transfer" ? "#{d.from_account_name || '?'}→#{d.to_account_name || '?'}" : (d.transaction_type_name || "no category"))
      parts << "fee #{fmt(d.fee_amount)}" if d.fee_amount
      parts << "on #{d.transaction_date}" if d.transaction_date && d.transaction_date != Date.current
      parts << "unresolved: #{d.unresolved.join(', ')}" if d.unresolved.present?
      parts.join(" · ")
    end

    def expectation(kase)
      e = kase[:expect] || {}
      bits = []
      bits << "kind #{e[:kind]}" if e[:kind]
      bits << "amount #{fmt(e[:amount])}" if e[:amount]
      bits << "category #{TransactionTaxonomy.name(e[:category], kase[:locale]) || e[:category]}" if e[:category]
      bits.join(" · ")
    end

    def print_summary(results)
      reg = results.select { |r| r[:case][:bank] == :regression }
      cha = results.select { |r| r[:case][:bank] == :challenge }
      reg_fail = reg.count { |r| r[:status] == :review }
      gaps = cha.count { |r| r[:status] == :review }

      puts "\n#{bold('SUMMARY')}"
      puts "  regression : #{reg.size - reg_fail}/#{reg.size} parsing as expected" +
           (reg_fail.positive? ? yellow("  ← #{reg_fail} regression(s) to investigate") : green("  ✓"))
      puts "  challenge  : #{gaps}/#{cha.size} phrases not handled yet (candidate additions below)"
    end

    def print_suggestions(results)
      gaps = results.select { |r| r[:status] == :review && r[:case][:bank] == :challenge && r[:case][:suggest] }
      return if gaps.empty?

      puts "\n#{bold('SUGGESTED ADDITIONS')} #{dim('(validate each, then edit the config)')}"
      gaps.group_by { |r| r[:case][:fix] }.each do |fix, rows|
        puts "\n  #{bold(FIX_LABELS[fix] || fix.to_s)}"
        rows.each { |r| puts "    • #{r[:case][:suggest]}  #{dim("[#{r[:case][:text]}]")}" }
      end
      puts ""
    end

    # --- formatting helpers -------------------------------------------------

    def fmt(amount)
      return "—" if amount.nil?

      n = amount.to_i == amount ? amount.to_i : amount
      n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse
    end

    def region(kase)
      kase[:region] ? dim("   [#{kase[:region]}]") : ""
    end

    def tty? = $stdout.tty?
    def bold(s)   = tty? ? "\e[1m#{s}\e[0m" : s
    def dim(s)    = tty? ? "\e[2m#{s}\e[0m" : s
    def green(s)  = tty? ? "\e[32m#{s}\e[0m" : s
    def yellow(s) = tty? ? "\e[33m#{s}\e[0m" : s

    # --- the corpus ---------------------------------------------------------
    # Expectations only assert what the rules brain can know without persisted accounts/debts
    # (amount, kind, category). Transfer from/to and debt linking depend on the space's own
    # accounts/contacts, so they're shown but not graded.

    def corpus
      [
        # ============================ REGRESSION ============================
        # Vocabulary already wired into the dictionaries — these should stay green.
        reg("2000 zem", :fr, amount: 2000, kind: "expense", category: "moto_taxi", region: "BJ"),
        reg("garba à 500 à midi", :fr, amount: 500, category: "street_food", region: "CI"),
        reg("woro-woro jusqu'à Adjamé 200", :fr, amount: 200, category: "public_transport", region: "CI"),
        reg("gbaka pour le boulot 250", :fr, amount: 250, category: "public_transport", region: "CI"),
        reg("Gozem ce soir 1500", :fr, amount: 1500, category: "ride_hailing", region: "TG"),
        reg("alloco poulet 1500", :fr, amount: 1500, category: "street_food", region: "CI"),
        reg("dibi à la dibiterie 3000", :fr, amount: 3000, category: "street_food", region: "SN"),
        reg("maquis avec les amis 2000", :fr, amount: 2000, category: "restaurant_maquis", region: "CI"),
        reg("courses à Auchan 23000", :fr, amount: 23_000, category: "groceries", region: "SN"),
        reg("pagne wax 12000", :fr, amount: 12_000, category: "clothing_shoes"),
        reg("reçu 50000 salaire", :fr, amount: 50_000, kind: "income", category: "salary"),
        reg("crédit Orange 1000", :fr, amount: 1000, category: "airtime"),
        reg("forfait internet 2500", :fr, amount: 2500, category: "mobile_data"),
        reg("facture SENELEC 18000", :fr, amount: 18_000, category: "electricity", region: "SN"),
        reg("facture SODECI 9000", :fr, amount: 9000, category: "water", region: "CI"),
        reg("loyer 75000", :fr, amount: 75_000, category: "rent"),
        reg("écolage 50000", :fr, amount: 50_000, category: "school_fees"),
        reg("pharmacie 3500", :fr, amount: 3500, category: "pharmacy"),
        reg("tontine du mois 10000", :fr, amount: 10_000, category: "tontine"),
        reg("5000 essence kpayo hier", :fr, amount: 5000, category: "fuel", region: "BJ"),
        reg("deux mille cinq cents taxi", :fr, amount: 2500, category: "public_transport"),
        reg("5k groceries", :en, amount: 5000, category: "groceries"),
        reg("transféré 300k de Wave à MTN, 700 de frais", :fr, amount: 300_000, kind: "transfer"),
        reg("j'ai prêté 20000 à Koffi", :fr, amount: 20_000, kind: "debt_out"),
        reg("emprunté 15000 à la banque", :fr, amount: 15_000, kind: "debt_in"),

        # ============================ CHALLENGE =============================
        # --- Nouchi amount units (Côte d'Ivoire): [n] × unit, not the leading digit ---
        cha("zem 3 barres", :fr, amount: 3000, category: "moto_taxi", fix: :number, region: "CI",
            suggest: 'add "barre/ba/krika/krikat" = 1 000 to fr numbers.scales'),
        cha("garba 2 gbonhon", :fr, amount: 10_000, category: "street_food", fix: :number, region: "CI",
            suggest: 'add "gbonhon/gbôh/gbon" = 5 000 to fr numbers.scales'),
        cha("loyer 1 brique", :fr, amount: 1_000_000, category: "rent", fix: :number, region: "CI",
            suggest: 'add "brique/briquette/bâton/plaque" = 1 000 000 to fr numbers.scales'),
        cha("un gbonhon de carburant", :fr, amount: 5000, category: "fuel", fix: :number, region: "CI",
            suggest: '"gbonhon" alone = 5 000 — bare nouchi unit, no digit present'),
        cha("trois togos de crédit", :fr, amount: 300, category: "airtime", fix: :number, region: "CI",
            suggest: 'add "togo/plon" = 100 (⚠ "togo" can also mean 100 000 — disambiguate by magnitude)'),

        # --- "digit + scale-word" (the most common way amounts are written) ---
        cha("15 mille pour le marché", :fr, amount: 15_000, category: "groceries", fix: :logic,
            suggest: '"15 mille" parses as 15 — digit_amount short-circuits before "mille" multiplies. Affects "X mille/k/million" everywhere; very high frequency'),
        cha("salaire 150 mille", :fr, amount: 150_000, kind: "income", category: "salary", fix: :logic,
            suggest: '"150 mille" → 150 (same digit+scale-word gap), here on a salary'),
        cha("loyer payé 100 mille", :fr, amount: 100_000, category: "rent", fix: :logic,
            suggest: '"100 mille" → 100 (digit+scale-word gap)'),

        # --- Mobile-money brand-as-verb = a transfer (huge regional pattern) ---
        cha("wave 10k à maman", :fr, amount: 10_000, kind: "transfer", fix: :keyword, region: "SN/CI",
            suggest: 'add wallet brands as transfer verbs: "wave/flooz/momo/om/orange money/djamo" → fr kind.transfer'),
        cha("flooz 2 mille à Koffi", :fr, kind: "transfer", fix: :keyword, region: "TG/BJ",
            suggest: '"flooz" → transfer verb (also note "2 mille" → 2, digit+scale-word gap)'),
        cha("fais OM 5000 à mon frère", :fr, amount: 5000, kind: "transfer", fix: :keyword,
            suggest: '"OM"/"orange money"/"fais OM" → transfer verb'),

        # --- Debt / lending slang (direction read from grammar) ---
        cha("j'ai dépanné Ali de 5000", :fr, amount: 5000, kind: "debt_out", fix: :keyword,
            suggest: 'add "dépanné/dépanner" → debt_lent (front someone cash)'),
        cha("il m'a dépanné 8000", :fr, amount: 8000, kind: "debt_in", fix: :keyword,
            suggest: '"dépanné" with "il m\'a…" → debt_borrowed — direction comes from grammar, not the word'),
        cha("soutra mon ami 10000", :fr, amount: 10_000, kind: "debt_out", fix: :keyword, region: "CI",
            suggest: 'add "soutra/soutrer" → debt_lent (nouchi: help out financially)'),

        # --- Dishes & venues people log by name (no merchant brand) ---
        cha("thieb chez la dame 700", :fr, amount: 700, category: "street_food", fix: :alias, region: "SN",
            suggest: 'add "thieb/thiéboudienne/ceebu jën/tiep" → street_food'),
        cha("shawarma 2500", :fr, amount: 2500, category: "street_food", fix: :alias,
            suggest: 'add "shawarma/chawarma" → street_food'),
        cha("yassa poulet 1500", :fr, amount: 1500, category: "street_food", fix: :alias, region: "SN",
            suggest: 'add "yassa/mafé/kédjenou/poulet braisé/choukouya/riz gras" → street_food'),
        cha("attiéké poisson 800", :fr, amount: 800, category: "street_food", fix: :alias, region: "CI",
            suggest: 'add bare "attiéké/atchéké/attchéké" → street_food (only "garba" is mapped today)'),
        cha("tangana ce matin 600", :fr, amount: 600, category: "street_food", fix: :alias, region: "SN",
            suggest: 'add "tangana/gargote/gargotte" → street_food (cheap canteen)'),

        # --- Transport names by city ---
        cha("sotrama jusqu'au marché 150", :fr, amount: 150, category: "public_transport", fix: :alias, region: "ML",
            suggest: 'add "sotrama/duruni" → public_transport (Bamako minibus)'),
        cha("car rapide 200", :fr, amount: 200, category: "public_transport", fix: :alias, region: "SN",
            suggest: 'add "car rapide/ndiaga ndiaye/magbana" → public_transport (Dakar/Conakry)'),
        cha("djakarta jusqu'à la maison 300", :fr, amount: 300, category: "moto_taxi", fix: :alias, region: "BJ/NE",
            suggest: 'add "djakarta/oléyia/kabu-kabu/kekeno" → moto_taxi'),

        # --- Income slang & remittances ---
        cha("gombo 15000 ce weekend", :fr, amount: 15_000, kind: "income", fix: :keyword,
            suggest: 'add "gombo" → income/side_hustle (⚠ also slang for a bribe — flag for review)'),
        cha("bénef 8 mille sur la vente", :fr, amount: 8000, kind: "income", category: "sales", fix: :keyword,
            suggest: 'add "bénef" → income (note: "vente" already maps to sales; "8 mille" → 8 digit gap)'),
        cha("mandat de 100000 reçu de Paris", :fr, amount: 100_000, kind: "income", category: "remittance", fix: :alias,
            suggest: 'add "mandat" → remittance ("reçu" already sets income; category is the gap)'),
        cha("le client m'a réglé 25 mille", :fr, kind: "income", fix: :keyword,
            suggest: 'add "réglé/m\'a réglé/m\'a payé" → income (also "25 mille" → 25 digit gap)'),

        # --- Utilities by local brand ---
        cha("Woyofal 5000", :fr, amount: 5000, category: "electricity", fix: :alias, region: "SN",
            suggest: 'add "woyofal" → electricity (Senelec prepaid scratch-code)'),
        cha("cash power 3000", :fr, amount: 3000, category: "electricity", fix: :alias, region: "BF/TG",
            suggest: 'add "cash power" → electricity (prepaid meter top-up)'),
        cha("friperie 5000", :fr, amount: 5000, category: "clothing_shoes", fix: :alias,
            suggest: 'add "friperie/fripe/bazin/boubou" → clothing_shoes'),

        # --- Wolof amount system (Senegal): spoken unit × 5 ---
        cha("junni pour le taxi", :fr, amount: 5000, category: "public_transport", fix: :number, region: "SN",
            suggest: 'Wolof money counts in dërëm (×5): "junni"=5 000, "téeméer"=500. Detect Wolof number words → multiply by 5'),

        # --- Overloaded keyword: "recharge" already means a transfer in fr ---
        cha("recharge crédit Orange 1000", :fr, amount: 1000, kind: "expense", category: "airtime", fix: :logic,
            suggest: '"recharge" is a fr transfer kind-keyword, but "recharge crédit/unités" is an airtime top-up. Disambiguate by the neighbouring word'),

        # ================= BENIN DEEP-DIVE (Cotonou · Porto-Novo · Parakou) =================
        # Researched from how people actually talk: Fon/Goun/Yoruba code-mixing, local dishes,
        # zem/kpayo, MoMo/Flooz/Celtiis, Dantokpa/Erevan. Regression rows avoid the "mille" bug
        # (bare digits / "k" / spelled numbers) so they isolate vocabulary coverage.

        # ---- Benin: already supported (regression) ----
        reg("zem au boulot 300", :fr, amount: 300, category: "moto_taxi", region: "BJ"),
        reg("zémidjan Calavi 500", :fr, amount: 500, category: "moto_taxi", region: "BJ"),
        reg("tokpa-tokpa 200", :fr, amount: 200, category: "public_transport", region: "BJ"),
        reg("taxi-brousse Bohicon 1500", :fr, amount: 1500, category: "public_transport", region: "BJ"),
        reg("kpayo 1000 pour la moto", :fr, amount: 1000, category: "fuel", region: "BJ"),
        reg("essence 3000", :fr, amount: 3000, category: "fuel", region: "BJ"),
        reg("akpan 100 ce matin", :fr, amount: 100, category: "street_food", region: "BJ"),
        reg("chez la bonne dame 500", :fr, amount: 500, category: "street_food", region: "BJ"),
        reg("beignet 200", :fr, amount: 200, category: "street_food", region: "BJ"),
        reg("sodabi à la buvette 400", :fr, amount: 400, category: "bar_buvette", region: "BJ"),
        reg("tchoukoutou 300", :fr, amount: 300, category: "bar_buvette", region: "BJ"),
        reg("maquis le midi 2500", :fr, amount: 2500, category: "restaurant_maquis", region: "BJ"),
        reg("courses à Erevan 15000", :fr, amount: 15_000, category: "groceries", region: "BJ"),
        reg("Mont Sinaï 12000", :fr, amount: 12_000, category: "groceries", region: "BJ"),
        reg("crédit MTN 500", :fr, amount: 500, category: "airtime", region: "BJ"),
        reg("forfait Moov 1000", :fr, amount: 1000, category: "mobile_data", region: "BJ"),
        reg("pass internet 1500", :fr, amount: 1500, category: "mobile_data", region: "BJ"),
        reg("facture SBEE 5000", :fr, amount: 5000, category: "electricity", region: "BJ"),
        reg("courant SBEE 3000", :fr, amount: 3000, category: "electricity", region: "BJ"),
        reg("facture SONEB 4000", :fr, amount: 4000, category: "water", region: "BJ"),
        reg("loyer 35000", :fr, amount: 35_000, category: "rent", region: "BJ"),
        reg("écolage des enfants 50000", :fr, amount: 50_000, category: "school_fees", region: "BJ"),
        reg("bonbonne de gaz 4500", :fr, amount: 4500, category: "cooking_gas", region: "BJ"),
        reg("coiffure 3000", :fr, amount: 3000, category: "salon_beauty", region: "BJ"),
        reg("couture chez le tailleur 5000", :fr, amount: 5000, category: "tailoring", region: "BJ"),
        reg("médicament à la pharmacie 2300", :fr, amount: 2300, category: "pharmacy", region: "BJ"),
        reg("consultation 5000", :fr, amount: 5000, category: "consultation", region: "BJ"),
        reg("cotisation tontine 5000", :fr, amount: 5000, category: "tontine", region: "BJ"),
        reg("dîme à l'église 5000", :fr, amount: 5000, category: "donations", region: "BJ"),
        reg("cadeau pour le mariage 10000", :fr, amount: 10_000, category: "ceremonies", region: "BJ"),
        reg("dot 200000", :fr, amount: 200_000, category: "ceremonies", region: "BJ"),
        reg("billet Baobab Express 8000", :fr, amount: 8000, category: "flights_tickets", region: "BJ"),
        reg("photocopie au cyber 200", :fr, amount: 200, category: "printing_admin", region: "BJ"),
        reg("reçu salaire 120000", :fr, amount: 120_000, kind: "income", category: "salary", region: "BJ"),
        reg("vente du jour 40000", :fr, amount: 40_000, kind: "income", category: "sales", region: "BJ"),
        reg("perdiem mission 30000", :fr, amount: 30_000, kind: "income", category: "allowance_perdiem", region: "BJ"),
        reg("remboursement reçu 15000", :fr, amount: 15_000, kind: "income", category: "refund", region: "BJ"),
        reg("Western Union reçu 75000", :fr, amount: 75_000, kind: "income", category: "remittance", region: "BJ"),
        reg("j'ai prêté 5000 à mon apprenti", :fr, amount: 5000, kind: "debt_out", region: "BJ"),
        reg("je dois 10000 à Maman Bénédicte", :fr, amount: 10_000, kind: "debt_in", region: "BJ"),

        # ---- Benin: dishes & street food the parser misses (→ street_food) ----
        cha("amiwo poisson 500", :fr, amount: 500, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "amiwo/amiwô/djèwo" -> street_food (flagship Fon dish)'),
        cha("akassa monyo 300", :fr, amount: 300, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "akassa/akassa-ata" and "monyo/monyɔ" -> street_food (only "akpan" is mapped today)'),
        cha("télibo dékoun 700", :fr, amount: 700, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "télibo/telibo/dékoun" -> street_food'),
        cha("ablo 200", :fr, amount: 200, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "ablo/ablô" -> street_food (steamed corn bread)'),
        cha("ayimolou 400", :fr, amount: 400, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "ayimolou/awɔ/riz-haricot" -> street_food'),
        cha("atassi sauce graine 600", :fr, amount: 600, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "atassi/atadelin/atadidi" and "sauce graine/arachide/dessi" -> street_food'),
        cha("watché du nord 500", :fr, amount: 500, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "watché/watche" -> street_food (northern rice-and-beans)'),
        cha("gboma dessi 800", :fr, amount: 800, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "gboma/gboma dessi/gbomadessi" -> street_food'),
        cha("sauce arachide 1000", :fr, amount: 1000, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "sauce arachide/sauce légume" -> street_food'),
        cha("wagasi 600", :fr, amount: 600, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "wagasi/wagashi/wara/fromage peulh" -> street_food (Fulani cheese)'),
        cha("dèguè 200", :fr, amount: 200, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "dèguè/dégué/deguê" -> street_food (millet + yogurt)'),
        cha("yovo doko 100", :fr, amount: 100, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "yovo doko/yovodoko" -> street_food (wheat-flour beignet)'),
        cha("botokoin 150", :fr, amount: 150, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "botokoin/gbofloto/bofloto/blofoto" -> street_food'),
        cha("ata haricot 100", :fr, amount: 100, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "ata/akara" -> street_food (cowpea fritters)'),
        cha("klaklo 100", :fr, amount: 100, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "klaklo/klako" -> street_food (plantain fritters)'),
        cha("massa 200", :fr, amount: 200, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "massa/masa" -> street_food (rice/millet pancakes, north)'),
        cha("kuli-kuli 100", :fr, amount: 100, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "kuli-kuli/klui-klui" -> street_food (peanut sticks)'),
        cha("piron 600", :fr, amount: 600, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "piron" -> street_food (low confidence, verify)'),
        cha("pâte rouge 400", :fr, amount: 400, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "pâte rouge/pâte noire/wô" -> street_food'),
        cha("wassa-wassa 500", :fr, amount: 500, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "wassa-wassa" -> street_food (grated-yam dish, north)'),
        cha("klako du soir 200", :fr, amount: 200, category: "street_food", fix: :alias, region: "BJ",
            suggest: 'add "klako" spelling variant -> street_food'),
        cha("liha 100", :fr, amount: 100, category: "bar_buvette", fix: :alias, region: "BJ",
            suggest: 'add "liha/lifri" -> bar_buvette (non-alcoholic corn drink, low confidence)'),

        # ---- Benin: transport & fuel gaps ----
        cha("kekeno Akpakpa 300", :fr, amount: 300, category: "moto_taxi", fix: :alias, region: "BJ",
            suggest: 'add bare "kekeno" (only accented "kèkènon" is mapped) -> moto_taxi'),
        cha("à la pompe 3000", :fr, amount: 3000, category: "fuel", fix: :alias, region: "BJ",
            suggest: 'add "pompe/à la pompe" -> fuel (pump petrol vs kpayo)'),
        cha("Confort Lines Cotonou 8000", :fr, amount: 8000, category: "flights_tickets", fix: :alias, region: "BJ",
            suggest: 'add inter-city coaches "confort lines/att/pax express/africa trans" -> flights_tickets'),
        cha("Pétrolin 5000", :fr, amount: 5000, category: "fuel", fix: :alias, region: "BJ",
            suggest: 'add Benin fuel brands "pétrolin/mrs/total" -> fuel'),

        # ---- Benin: mobile-money brand/verb = a transfer ----
        cha("MoMo 10k à maman", :fr, amount: 10_000, kind: "transfer", fix: :keyword, region: "BJ",
            suggest: 'add "momo/fais-moi momo/momo-moi" -> fr kind.transfer (MTN MoMo as a verb)'),
        cha("fais-moi MoMo 5000", :fr, amount: 5000, kind: "transfer", fix: :keyword, region: "BJ",
            suggest: '"fais-moi MoMo" -> transfer (request to receive money)'),
        cha("envoie Flooz 2000 à Koffi", :fr, amount: 2000, kind: "transfer", fix: :keyword, region: "BJ",
            suggest: 'add "flooz" (unknown today, not even an instrument) -> transfer + momo instrument'),
        cha("Celtiis Cash 15000 à mon frère", :fr, amount: 15_000, kind: "transfer", fix: :keyword, region: "BJ",
            suggest: 'add "celtiis/celtiis cash" -> transfer + momo instrument (Benin state wallet)'),
        cha("Wave 5000 à ma sœur", :fr, amount: 5000, kind: "transfer", fix: :keyword, region: "BJ",
            suggest: '"wave" is an instrument but not a transfer verb -> add to kind.transfer'),
        cha("on m'a viré 50000 de Paris", :fr, kind: "income", amount: 50_000, fix: :logic, region: "BJ",
            suggest: 'a received transfer ("on m\'a viré/envoyé") is income (remittance), not an internal transfer'),

        # ---- Benin: income slang ----
        cha("le client a payé ma commande 25000", :fr, kind: "income", category: "sales", fix: :alias, region: "BJ",
            suggest: 'add "commande" -> sales (kind already set via "payé")'),
        cha("j'ai vendu pour 30000", :fr, kind: "income", category: "sales", fix: :alias, region: "BJ",
            suggest: 'add "vendu" -> sales so the category resolves (kind already income)'),
        cha("pourboire du client 1000", :fr, kind: "income", fix: :keyword, region: "BJ",
            suggest: 'add "pourboire/motivation/ils m\'ont motivé" -> income'),
        cha("les clients m'ont motivé 2000", :fr, kind: "income", fix: :keyword, region: "BJ",
            suggest: '"motivé/motivation" (tip) -> income'),
        cha("ma débrouille du jour 5000", :fr, kind: "income", fix: :keyword, region: "BJ",
            suggest: 'add "débrouille/je me débrouille" -> income (informal earning)'),
        cha("bizness du jour 20000", :fr, kind: "income", fix: :keyword, region: "BJ",
            suggest: 'add "bizness/biz" -> income/business'),

        # ---- Benin: debt / lending slang & conflicts ----
        cha("j'ai dépanné mon apprenti 2000", :fr, amount: 2000, kind: "debt_out", fix: :keyword, region: "BJ",
            suggest: 'add "dépanné/dépanner" -> debt_lent (may already pass where it was learned)'),
        cha("Koffi me doit 7000", :fr, amount: 7000, kind: "debt_out", fix: :keyword, region: "BJ",
            suggest: 'add "me doit/tu me dois/on me doit" -> debt_lent (they owe me)'),
        cha("crédit chez la boutiquière 1500", :fr, kind: "debt_in", fix: :logic, region: "BJ",
            suggest: '"à crédit/crédit chez la boutiquière" is buying on tab (debt), but "crédit" resolves to airtime'),
        cha("avance sur salaire 25000", :fr, kind: "debt_in", fix: :logic, region: "BJ",
            suggest: '"avance" always maps to debt_lent (debt_out); "avance sur salaire" means money received now, owed later'),
        cha("le collecteur est passé 500", :fr, category: "tontine", fix: :alias, region: "BJ",
            suggest: 'add "collecteur" -> tontine/savings (daily savings collector)'),
        cha("adogbe 5000", :fr, category: "tontine", fix: :alias, region: "BJ",
            suggest: 'add "adogbe/adɔgbɛ" -> tontine (LOW CONFIDENCE — verify Fon term with a native speaker)'),
        cha("ndjonu 3000", :fr, kind: "debt_in", fix: :keyword, region: "BJ",
            suggest: 'add "ndjonu/njɔnu" -> debt (LOW CONFIDENCE — verify Fon/Goun term)'),

        # ---- Benin: utilities & housing conflicts/gaps ----
        cha("caution 100000", :fr, category: "rent", fix: :alias, region: "BJ",
            suggest: 'add "caution" -> rent (rental security deposit)'),
        cha("avance 6 mois de loyer 180000", :fr, kind: "expense", category: "rent", fix: :logic, region: "BJ",
            suggest: '"avance" hijacks this to debt_out; "avance de X mois de loyer" is rent paid upfront'),
        cha("j'ai mis 5000 de CASH", :fr, amount: 5000, category: "electricity", fix: :alias, region: "BJ",
            suggest: 'add "cash/cash power" (next to a meter context) -> electricity (SBEE prepaid)'),

        # ---- Benin: social / ceremonies / clothing gaps ----
        cha("friperie à Missebo 3000", :fr, amount: 3000, category: "clothing_shoes", fix: :alias, region: "BJ",
            suggest: 'add "friperie/fripe/missebo" -> clothing_shoes (secondhand-clothes hub)'),
        cha("le cotonou 2000", :fr, amount: 2000, category: "clothing_shoes", fix: :alias, region: "BJ",
            suggest: 'add "cotonou/atchouta" -> clothing_shoes (local nicknames for secondhand clothes)'),
        cha("levée de corps 50000", :fr, amount: 50_000, category: "ceremonies", fix: :alias, region: "BJ",
            suggest: 'add "levée de corps/obsèques/se réjouir" -> ceremonies'),
        cha("sapé pour la fête 15000", :fr, category: "clothing_shoes", fix: :alias, region: "BJ",
            suggest: '"fête" pulls this to outings; add "sapé/se saper" -> clothing_shoes'),

        # ---- Benin: the "<digit> mille" amount bug (how amounts are really written) ----
        cha("zem 2 mille", :fr, amount: 2000, category: "moto_taxi", fix: :logic, region: "BJ",
            suggest: '"2 mille" -> 2 (digit+scale-word gap) on a zem ride'),
        cha("taxi 3 mille", :fr, amount: 3000, category: "public_transport", fix: :logic, region: "BJ",
            suggest: '"3 mille" -> 3'),
        cha("loyer 35 mille", :fr, amount: 35_000, category: "rent", fix: :logic, region: "BJ",
            suggest: '"35 mille" -> 35'),
        cha("salaire 90 mille", :fr, amount: 90_000, kind: "income", category: "salary", fix: :logic, region: "BJ",
            suggest: '"90 mille" -> 90 on a salary'),
        cha("écolage 60 mille", :fr, amount: 60_000, category: "school_fees", fix: :logic, region: "BJ",
            suggest: '"60 mille" -> 60'),
        cha("courses à Erevan 15 mille", :fr, amount: 15_000, category: "groceries", fix: :logic, region: "BJ",
            suggest: '"15 mille" -> 15 (covered category, wrong amount)'),
        cha("j'ai prêté 20 mille à Koffi", :fr, amount: 20_000, kind: "debt_out", fix: :logic, region: "BJ",
            suggest: '"20 mille" -> 20 (kind resolves, amount does not)'),
        cha("facture SBEE 5 mille", :fr, amount: 5000, category: "electricity", fix: :logic, region: "BJ",
            suggest: '"5 mille" -> 5'),
        cha("cadeau mariage 10 mille", :fr, amount: 10_000, category: "ceremonies", fix: :logic, region: "BJ",
            suggest: '"10 mille" -> 10')
      ]
    end

    def reg(text, locale, region: nil, **expect)
      { bank: :regression, text: text, locale: locale, region: region, expect: expect }
    end

    def cha(text, locale, fix:, suggest:, region: nil, **expect)
      { bank: :challenge, text: text, locale: locale, region: region, fix: fix, suggest: suggest, expect: expect }
    end
  end
end
