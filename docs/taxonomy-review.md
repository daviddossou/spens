# Revue de la taxonomie — proposition

Base : export production du 2026-09-01 (4 espaces, 46 gaps, 155 transactions sur
catégorie inventée).
Statut : **proposition à arbitrer**, pas une décision.

> ⚠️ Le premier export annonçait « 63 % non couvert ». Ce chiffre était **faux** :
> le calcul comptait les 12 kinds de transaction alors que la taxonomie n'en couvre
> que deux (`expense`, `income`). Virements, dettes, soldes de départ et ajustements
> n'ont aucun `template_key` **par construction** — ils étaient comptés comme des
> catégories inventées. Corrigé dans `TaxonomyExport#coverage` ; réexporter pour
> obtenir le vrai ratio. Les 155 transactions des gaps, elles, restent valides.

> La donnée valide les évidences (ce qui est massivement utilisé, ce que les gens
> ont dû inventer) mais 516 transactions ne tranchent pas les cas fins. Les
> arbitrages ci-dessous sont d'abord structurels : chaque parent doit être
> **homogène en essentialité**, sinon `default_essential` ment.

## Principes retenus

1. **Un parent = une enveloppe de budget.** S'il ne peut pas être une ligne de
   budget crédible, ce n'est pas un parent.
2. **Un parent est homogène en essentialité.** Vital, confort ou épargne — jamais
   un mélange. C'est la condition pour pré-remplir le formulaire.
3. **Deux terrains, un arbre.** Afrique de l'Ouest et diaspora. Aucun nœud
   spécifique à un terrain ne doit occuper une place de parent.
4. **Le nom de l'utilisateur est sacré.** On rattache, on ne renomme jamais.

## Essentialité — trois valeurs, pas deux

| Valeur | Sens | Formulaire |
|---|---|---|
| `vital` | Je ne peux pas m'en passer | Vital pré-coché |
| `confort` | Un plaisir, ajustable | Confort pré-coché |
| `epargne` | Ni dépense ni plaisir — ça reste à moi | Hors du partage vital/confort |

`savings_investment` casse le binaire aujourd'hui : ce n'est pas une dépense de
confort, et l'appeler « vital » fausse le ratio. D'où la troisième valeur.

---

# DÉPENSES — 21 parents (17 aujourd'hui)

## VITAL

### 1. `food_groceries` — 🛒 Marché & Alimentation · 66 tx
- `groceries` (64) — **garder**
- `monthly_provisions` (0) — **FUSIONNER dans `groceries`**
  La distinction « provisions du mois » vs « provisions » n'existe pas pour les
  utilisateurs : 64 contre 0. Elle coûte un choix et n'apporte rien.

### 2. `housing` — 🏠 Logement · (scindé de `housing_home`)
- `rent` (8) — garder
- `home_insurance` (1) — garder
- `security_guard` (0) — garder (pertinent Afrique de l'Ouest)
- `home_charges` — **CRÉER** (charges, copropriété, syndic)
> Scission motivée : `housing_home` mélangeait loyer (vital) et décoration
> (confort). Aucun défaut d'essentialité n'était honnête.

### 3. `utilities` — 💡 Énergie, Eau & Cuisson (fusion)
- `electricity` (0), `water` (0) — garder
- `cooking_gas` (0), `charcoal_wood` (0) — **DÉPLACER** depuis `kitchen_supplies`
> `kitchen_supplies` est à 0 tx / 0 espace. Gaz et charbon *sont* de l'énergie
> domestique ; les ustensiles n'ont rien à y faire (voir `home_equipment`).
> `kitchen_supplies` disparaît comme parent.

### 4. `telecom_internet` — 📱 Télécom & Internet · 11 tx
- `airtime`, `mobile_data`, `home_internet` — garder tels quels
> Gaps à rattacher : « Forfait Max », « Forfait Max+ ».

### 5. `transport` — 🚍 Transport · 25 tx
- `public_transport` (20), `ride_hailing` (5) — garder
- `moto_taxi` (0), `fuel` (0), `parking_tolls`, `vehicle_upkeep` — garder
- `goods_transport` (0) — **DÉPLACER** vers `other_expense/business_work_expense`
> Le transport de marchandises est une dépense pro, pas un déplacement personnel.

### 6. `health` — 💊 Santé · 1 tx — inchangé

### 7. `education` — 🎓 Éducation · 0 tx — inchangé
> 0 usage, mais indispensable structurellement (scolarité = poste majeur).
> À garder même vide.

### 8. `family_obligations` — 🤝 Soutien & Obligations (scindé de `family_social`)
- `family_support` (0) — garder
- `childcare` (0) — garder
> En Afrique de l'Ouest le soutien familial est **subi et récurrent**, pas un
> plaisir. Le mettre avec les cadeaux le rendait ajustable, ce qu'il n'est pas.

### 9. `fees_taxes` — 💳 Frais & Impôts · 19 tx (unification)
- `mobile_money_fees` (12), `withdrawal_send_fees` (2), `taxes` (5) — garder
- `bank_fees` (0) — garder
- `investment_fees` (7) — **DÉPLACER** depuis `savings_investment`
- `online_payment_fees` — **CRÉER** (gap : 9 tx)
- `currency_conversion_fees` — **CRÉER** (gap : 1 tx, Wise USD↔EUR)
> 28 transactions de frais errent dans les gaps. Tous les frais au même endroit :
> c'est un poste réel et croissant en économie mobile money + diaspora.

### 10. `money_transfers` — 💸 Envois d'argent — **NOUVEAU PARENT**
- `remittance_sent` — envoi à la famille
- `household_contribution_out` — contribution au ménage commun
> **Trou structurel** : l'income a `transfers_received`, la dépense n'avait aucun
> miroir. Les gaps le prouvent : « Envoi Moneco », « Contribution DD » (3),
> « Contribution du mois David » (3), « Doris » (3) = 10 tx inventées.

## CONFORT

### 11. `eating_out` — 🍽️ Repas à l'extérieur · 29 tx
- `food_delivery` (18), `restaurant_maquis` (7), `cafe_snacks` (3) — garder
- `street_food` (0), `bar_buvette` (0) — garder
> `food_delivery` domine : signal diaspora net. Ne pas le sous-estimer.

### 12. `home_equipment` — 🛋️ Maison & Équipement (scindé de `housing_home`)
- `household_items` (0), `home_repairs` (2), `home_supplies` (0),
  `cleaning_laundry` (0), `domestic_help` (0) — déplacés depuis `housing_home`
- `kitchen_utensils`, `kitchen_consumables` — déplacés depuis `kitchen_supplies`

### 13. `clothing_accessories` — 👕 Vêtements & Accessoires (scindé)
- `clothing_shoes` (2), `tailoring` (0) — garder
- `jewelry_accessories` — **CRÉER** (bijoux, sacs, montres — gap : « Bijoux »)

### 14. `personal_care` — 💇 Soins & Beauté (scindé)
- `salon_beauty` (0), `cosmetics` (1) — garder
- `cosmetics` accueille aussi le parfum

> Scission par **rythme de budget**, pas par volume (3 tx, insignifiant) : le salon
> et les cosmétiques sont récurrents et prévisibles — une ligne mensuelle stable.
> Les vêtements sont épisodiques et lourds. Ensemble, ils rendent le budget
> illisible : on ne sait jamais si le dépassement vient du coiffeur ou d'un manteau.
> « Shopping » a été écarté : c'est un mode d'achat, pas un besoin — le nœud
> deviendrait un aimant à fourre-tout.

### 15. `recreation_lifestyle` — 🎬 Loisirs & Style de vie · 1 tx
- `outings`, `betting_games`, `sport_fitness`, `photo` — garder
- `subscriptions_fun` (0) — **SUPPRIMER**, absorbé par le parent `subscriptions` (18)

### 16. `celebrations_gifts` — 🎁 Cadeaux & Cérémonies (scindé de `family_social`)
- `gifts` (0), `ceremonies` (0), `donations` (0)
> Gaps rattachés : « Cadeaux (Dépense) » 10, « Quête / Offrande » 7,
> « Myri/Maman/Doris (Cadeaux) » 8.
> ⚠️ Les cadeaux nommés par personne signalent un besoin de dimension
> **personne**, pas de nouveaux nœuds. Ne pas créer « Cadeaux Maman ».

### 17. `technology_tools` — 💻 Technologie & Matériel · 2 tx
- `electronics` (2), `appliances`, `computer_accessories` — garder
- `software_digital` (0) — **DÉPLACER** vers le nouveau parent `subscriptions`

### 18. `subscriptions` — 🔁 Abonnements — **NOUVEAU PARENT** · `confort`
- `streaming_media` — Netflix, Spotify, Prime, YouTube
- `cloud_storage` — Google One, iCloud, Dropbox
- `software_tools` — Canva, Notion, applications
- `other_subscriptions` — presse, box, salle de sport en engagement
> **Pourquoi un parent à part, et non deux nœuds par finalité.**
> Cinq gaps emploient le mot « Abonnement » : Productivité (3), Boulot (2),
> Souscriptions, Musique & Streaming (3), Services de streaming (1). Personne n'a
> tapé « logiciel » ni « service numérique » — l'ancien nom était du jargon.
> Séparer loisir / travail force un arbitrage sans bonne réponse : Spotify pour
> courir, Google One qui stocke photos de famille ET documents de travail, Prime
> qui est livraison et streaming. C'est exactement pourquoi `subscriptions_fun`
> n'a jamais été trouvé.
> Surtout : le problème des abonnements n'est pas *lequel* couper, c'est
> **l'accumulation silencieuse** — 9,99 + 6,99 + 11,99 qu'on ne voit jamais
> additionnés. Un seul total déclenche l'action ; deux moitiés ne déclenchent rien.
> Séparer détruirait le chiffre qui sert.
> Homogène par nature : un abonnement est un engagement récurrent résiliable —
> tout ce qui est dedans est coupable, donc `confort` est honnête.
> Ce n'est pas l'erreur « Shopping » : celui-ci était **non borné** (il traverse
> tous les besoins et finit par tout avaler). « Abonnements » est **borné et
> énumérable**. Grouper par récurrence est défendable ici parce que la récurrence
> EST la propriété budgétairement pertinente.
> Les vrais outils professionnels (Hetzner, SaaS métier) vont dans
> `other_expense/business_work_expense` — ce ne sont pas des dépenses de ménage.

### 19. `travel` — ✈️ Voyage · 0 tx — inchangé

## ÉPARGNE

### 20. `savings_investment` — 💰 Épargne & Investissement · 7 tx
- `savings_deposit`, `tontine`, `investment`, `land_construction` — garder
- `investment_fees` — **SORTIR** vers `fees_taxes`
- `investment_loss` — **CRÉER** (gap : « Perte investissement » 5)
> `essential` = `epargne`. Les lignes de portefeuille inventées
> (« FTSE All World », « MSCI Emerging Markets ») ne deviennent PAS des nœuds :
> c'est du suivi d'actifs, hors périmètre d'un budget.

## NEUTRE

### 21. `other_expense` — ❓ Autre · 1 tx
- inchangé. Reste un **dernier recours**, jamais un classeur.

---

# REVENUS — 7 parents (inchangé)

### `salary_employment` · 4 tx — inchangé
### `business_trade` · 0 tx — inchangé
### `transfers_received` · 0 tx
- + `household_contribution_in` — **CRÉER** (miroir de la contribution ménage)

### `investment_returns` · 3 tx
- `bank_cashback` (0) — **FUSIONNER dans `refunds_reimbursements/cashback_rewards`**
> Doublon franc : « cashback bancaire » et « remises & récompenses » sont la même
> chose vue deux fois.

### `refunds_reimbursements` · 1 tx — récupère `cashback_rewards` unifié
### `gifts_windfall` · 0 tx — inchangé
### `other_income` · 0 tx — inchangé

> `⚖️ Ajustement de solde` a été **retiré de cette revue** : ce n'est pas une
> décision de taxonomie. Voir « Hors périmètre » en fin de document.

---

# Bilan

| | Avant | Après |
|---|---|---|
| Parents dépense | 17 | 21 |
| Parents à 0 usage | 4 | 2 |
| Parents non homogènes | 3 | 0 |

**Scissions** : `housing_home` → `housing` + `home_equipment` ;
`family_social` → `family_obligations` + `celebrations_gifts` ;
`clothing_personal_care` → `clothing_accessories` + `personal_care`
**Fusions** : `kitchen_supplies` → `utilities` + `home_equipment` ;
`monthly_provisions` → `groceries` ; `bank_cashback` → `cashback_rewards`
**Nouveaux parents** : `money_transfers`, `subscriptions`
**Nœuds créés** : 7 · **Nœuds déplacés** : 8 · **Nœuds fusionnés** : 4

# Hors périmètre — deux correctifs d'implémentation

### `⚖️ Ajustement de solde` est créé par son nom traduit

```ruby
name = I18n.t("transactions.balance_adjustment.type_name")
type = FindOrCreateTransactionTypeService.new(space, name, "adjustment").call
```

Le nom n'étant celui d'aucun nœud, il tombe dans `find_or_create_by_name` et
naît avec `template_key: nil`. Deux effets :

1. il compte comme « inventé par l'utilisateur » dans la couverture ;
2. **il existe une fois par langue** — la production contient à la fois
   `⚖️ Balance adjustment` et `⚖️ Ajustement de solde`. Un utilisateur qui passe
   FR→EN obtient une seconde catégorie et son historique se coupe en deux.

Correctif : `template_key` système stable, création par clé et non par nom.
Même remarque pour `initial_balance` (`account_form.rb:115`).

Vérifié sur `main` à `70af12f` : le `key` présent dans `balance_movement_name` ne
sert qu'à choisir la chaîne i18n — ce n'est pas un `template_key`. Les clés
`balance_adjustment` / `initial_balance` sont absentes du YML, et ne peuvent pas y
être puisque `TransactionTaxonomy::KINDS` se limite à `expense` / `income`.
Le duplicata par langue est donc toujours actif.

Note : depuis le correctif de `coverage`, ces mouvements ne faussent plus la
mesure — mais le doublon FR/EN reste un vrai bug fonctionnel.

### Les 170 transactions déjà résolvables

Voir ci-dessous.

## Ce que cette revue ne règle PAS

Les doublons de vocabulaire : des catégories créées alors que le nom résolvait
déjà vers un nœud existant. Aucune modification de l'arbre ne les touche — c'est
le picker qui ne propose pas au bon moment.

Leur volume exact reste **inconnu** : il était estimé à 170 à partir du calcul de
couverture défectueux. À remesurer après réexport.
