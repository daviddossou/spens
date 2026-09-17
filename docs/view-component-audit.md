# Audit ViewComponent — 16 septembre 2026

État examiné : `1226259`. Inventaire statique des 118 templates ERB de `app/views`, des 27 classes de `app/components`, des helpers de rendu, des routes et des contrats Stimulus associés. Les previews ne sont pas comptées comme usages de production. Aucun changement fonctionnel ni test d'exécution dans cet audit.

Les chemins et lignes ci-dessous se rapportent à cet état du dépôt. P1 : duplication à traiter en premier ; P2 : extraction utile ensuite ; P3 : amélioration facultative. Les noms des nouveaux composants sont des propositions.

## 1. Réutiliser les composants existants

### P1 — Boutons : réutilisation directe

`Ui::ButtonComponent` couvre déjà `type`, `variant`, `size`, `disabled`, `data`, les attributs HTML, les liens et les blocs de contenu.

| Éléments écrits à la main | Emplacements | Migration |
|---|---|---|
| CTA de création/modification d'un compte | `app/views/accounts/new.html.erb:26`, `accounts/edit.html.erb:31` | `type: :submit`, `size: :lg`, conserver `account_form_target` et l'état initial désactivé à la création. |
| CTA de création/modification d'une dette | `app/views/debts/new.html.erb:38`, `debts/edit.html.erb:37` | Même migration, avec `debt_form_target`. |
| CTA de création/modification d'un objectif | `app/views/goals/new.html.erb:26`, `goals/edit.html.erb:26` | Même migration, avec `goal_form_target`. |
| Enregistrement d'une enveloppe mensuelle | `app/views/budget_entries/edit.html.erb:220` | Conserver `budget_scope_target`. |
| Application de la période personnalisée | `app/views/analytics/index.html.erb:33` | Remplacer `submit_tag`, conserver les paramètres GET. |
| Réactivation, compensation et restauration de règle | `app/views/debts/show.html.erb:60`, `:86`, `app/views/budget_entries/edit.html.erb:94` | Ce sont actuellement des liens avec `turbo_method` (`:post` pour compensation/restauration, `:delete` pour réactivation) : les options `url`, `method`, `classes` suffisent. |

Soit **8 boutons de soumission et 3 liens d'action** clairement remplaçables. Les boutons des catégories budgétaires ont déjà été migrés (`a7382bd`) ; ceux des transactions et de `budget_items/_form` utilisent également le composant.

Attention au comportement dynamique : `disabled: true` ajoute aussi la classe `disabled` dans le composant. Vérifier son interaction avec les contrôleurs qui activent ensuite le CTA, et pas seulement la présence de l'attribut HTML.

### P1/P2 — Champs : réutilisation directe ou petite adaptation

| Éléments | Emplacements | Composant et réserves |
|---|---|---|
| Adresse email de connexion | `app/views/auth/sessions/new.html.erb:8` | `Forms::InputFieldComponent`, `type: :email_field`. Il accepte un builder sans modèle pour la lecture des erreurs. |
| Code OTP | `app/views/auth/verifications/show.html.erb:13` | Même composant avec `field: :otp_code`, `inputmode`, `pattern`, `maxlength`, actions et targets OTP. Préserver le nom et l'identifiant exacts. |
| Dates ordinaires | `app/views/transactions/_form.html.erb:264`, `goals/_form.html.erb:64`, `debts/_form.html.erb:92`, `budget_items/_form.html.erb:221` | `Forms::InputFieldComponent`, `type: :date_field`. Préserver les targets et prévoir un libellé accessible : `label: ""` ne résout pas l'association avec les titres externes actuels. |
| Dates sans builder | `app/views/analytics/index.html.erb:31`, `:32`, `app/views/budget_entries/edit.html.erb:185` | Utiliser le builder du formulaire ou une variante adaptée. Préserver `start_date`, `end_date`, `budget_item[ends_on]`. Le composant stocke actuellement `name`/`id` dans des variables dédiées, mais son template ne les transmet pas au champ : corriger ce contrat avant de compter dessus. |
| Catégorie d'une correspondance | `app/views/spaces/mappings/index.html.erb:26` | Candidat pour `Forms::SelectFieldComponent`, **après adaptation** : options groupées, builder sans modèle (`has_errors?` suppose un objet), sélection courante et soumission automatique. Le HTML `grouped_options_for_select` n'est pas compatible tel quel avec sa conversion actuelle des options. |

### P1 — Cartes de choix : faire évoluer l'existant

`Ui::SelectableCardComponent` dispose déjà des modes radio, checkbox et lien, ainsi que du titre et de la description. Les cartes suivantes reproduisent ce concept :

- `app/views/accounts/_form.html.erb:30` : compte quotidien / épargne.
- `app/views/budget_items/_form.html.erb:167` et `app/views/budget_entries/edit.html.erb:139` : Vital / Confort, duplication directe.
- `app/views/debts/_form.html.erb:13` : prêt / emprunt.
- `app/views/transactions/_form.html.erb:165` et `app/views/budget_items/_form.html.erb:144` : sens d'un mouvement de dette.
- `app/views/budget_entries/edit.html.erb:102` : portée mois / règle.

Ce n'est pas un remplacement mécanique : le composant impose aujourd'hui son DOM, ses classes et `ui--selectable-card`; les nouvelles cartes utilisent des inputs natifs ou des boutons avec leurs propres contrôleurs. Ajouter une variante qui préserve la sémantique radio, les styles, l'état initial et les événements, en composant `Forms::RadioButtonFieldComponent` lorsque pertinent. Les valeurs booléennes `false` doivent rester des valeurs valides. Éviter deux contrôleurs concurrents qui modifient la même sélection.

### P2 — Switcher, statistiques et progression : réutilisation conditionnelle

| Existant | Candidats | Décision |
|---|---|---|
| `Ui::SwitcherComponent` | `analytics/index.html.erb:21`, `budgets/index.html.erb:24`; sélecteurs de type dans `transactions/_form.html.erb:62`, `budget_items/_form.html.erb:45`; onglets admin | Étendre les classes des options, les attributs ARIA et les options désactivées. Le composant produit uniquement des liens : ne pas l'utiliser tel quel pour les boutons qui modifient un champ. |
| `Ui::StatCardComponent` | `accounts/index.html.erb:8`, `accounts/show.html.erb:41`, `goals/index.html.erb`, `budgets/index.html.erb:39`, montants principaux d'`analytics/index.html.erb` | Étendre uniquement les variantes réellement communes. Préserver signe, précision monétaire et sous-contenu : les comptes utilisent `account_money`, le budget des montants explicitement signés. Les paires de montants appellent plutôt un composant composé. |
| `Ui::ProgressComponent` | Barres comptes, objectifs, dettes, budgets, analyses | Extraire une primitive `Ui::ProgressBarComponent` commune, ou enrichir l'existant. Il impose aujourd'hui `progress-bar`/`progress-fill` et ne produit pas lui-même les attributs ARIA d'une jauge. Ne pas confondre progression simple, répartition et histogramme. |
| `Ui::CommitmentCardComponent` | `goals/_goal_card.html.erb:1`, `goals/show.html.erb:30`, `accounts/show.html.erb:73`, `debts/_relation_row.html.erb:1`, `analytics/index.html.erb:350` | Aucun appel trouvé dans `app`. Le composant met en avant le **restant**, les objectifs actuels le **déjà épargné**, et les relations à double sens un **solde net**. Ajouter des variantes explicites seulement si cela simplifie l'API ; sinon le retirer au profit de composants métier partageant la jauge. Ne pas le réintroduire de force. |
| `Debts::HeroComponent` | `debts/show.html.erb:39` | Déjà utilisé pour une dette simple. Étendre pour une relation à double sens ou créer `Debts::RelationHeroComponent`; ne pas lui passer un objet relation à la place d'une dette. |

## 2. Nouveaux composants transversaux prioritaires

| Priorité | Composant proposé | Occurrences et intérêt |
|---|---|---|
| P1 | `Forms::AmountFieldComponent` | `accounts/_form:8`, `debts/_form:27`, `goals/_form:7`, `transactions/_form:80`, `budget_items/_form:62`, `budget_entries/edit:72`. Même bloc `budget-amount`, devise, décimales, texte de période, targets Stimulus. Accepter les contraintes propres au champ et préserver le cas sans builder. `InputFieldComponent` avec addon ne reproduit pas ce DOM. |
| P1 | `Ui::ActionMenuComponent` | `accounts/show:8`, `debts/show:8`, `goals/show:8`, `transactions/show:12`, `budget_entries/edit:37`, `budgets/categories/show:22`. Même structure `details/summary/panel`; slots pour déclencheur et actions, libellés secondaires, danger et attributs Turbo. Le menu de mois a un déclencheur différent à conserver. |
| P1 | `Forms::SegmentedChoiceComponent` | `goals/_form:53`, `debts/_form:77`, `transactions/_form:95` et `:256`, `budget_items/_form:201` et `:212`, `budget_entries/edit:166` et `:176`. Boutons de fréquence, échéance, date et propositions de montant. Interface commune pour options, sélection et attributs ; calcul des dates conservé dans les contrôleurs dédiés. |
| P1 | `Budgets::RecurrenceFieldsComponent` | `budget_items/_form:183`, `budget_entries/edit:155`. Regroupe fréquence, fin, report, résumé et champs cachés. La duplication porte sur tout le contrat `budget-line`, pas seulement sur les boutons. Accepter les valeurs et noms des champs explicitement. |
| P1 | `Forms::ToggleFieldComponent` ou variante de `CheckboxFieldComponent` | `budget_items/_form:228`, `budget_entries/edit:190`. Même interrupteur de report avec libellé, input, champ caché et piste visuelle. Préserver la valeur envoyée quand décoché. |
| P1 | `Transactions::TimelineComponent` + groupe journalier + pied de pagination | `shared/_transactions_list:1`, `home/show:103`, `accounts/show:98`, `debts/show:146`, `goals/show:63`, `budgets/categories/show:113`. Groupement, totaux et chargement répétés. Continuer à rendre `TransactionItemComponent`; conserver le calcul de total propre au contexte, les IDs et les targets du scroll. Le template Turbo Stream reste l'orchestrateur. |
| P1 | `Forms::ErrorsComponent` | `shared/_form_errors:1`, `devise/shared/_error_messages:1`, `admin/taxonomy_nodes/_form:2`. Une API `object`, titre et variante; préserver le comportement `data-turbo-cache`. Le partial Devise est encore utilisé par l'inscription actuelle et le profil. |
| P2 | `Ui::EmptyStateComponent` | `accounts/index:44`, `accounts/show:115`, `spaces/index:63`, `spaces/mappings/index:10`, `goals/show:80`, `debts/show:163`, `home/_empty_state:1`, `home/show:125`, `analytics/index:39`, `budgets/categories/show:129`, états initiaux de `budgets/index`, `goals/index`, `debts/index`; états vides admin. Titre, texte, illustration et actions optionnels. Les starters demeurent un sous-composant. |
| P2 | `Ui::StarterCardComponent` | `goals/_starter:1`, `debts/_starter:1`. Structure quasi identique `goal-starter`, icône, titre, aide, chevron et ouverture de modale. |
| P2 | `Ui::BottomSheetComponent` et `Forms::PickerLayerComponent` | `layouts/application:76`, `shared/_picker_layer:4`. Widgets autonomes avec contrat Stimulus, navigation et accessibilité à tester. Garder le picker **frère** de la sheet et conserver le frame `modal`. Les options générées côté JS ne nécessitent pas un rendu serveur par option. |
| P2 | `Ui::FieldHeadingComponent` ou slot de label des champs | `transactions/_form:241`, `:251`, `:270`, `debts/_form:51`, `:73`, `:98`. Motif `tx-detail__head` avec libellé et indication facultative; centraliser surtout l'association accessible au champ, actuellement séparée. |
| P2 | `Ui::PageHeaderComponent` | En-têtes new/edit de comptes, dettes, objectifs, budgets, transactions et espaces. Titre/sous-titre/actions; préserver les targets du titre dynamique de transaction. `Navigation::DetailHeaderComponent` est une barre de navigation, pas cet en-tête de formulaire. |
| P2 | `Ui::FlowSummaryComponent` | `home/show:23` et `:49`, `accounts/show:54`, `debts/index:9`, `debts/show:43`, `analytics/index:286`. Paires de montants, légendes et séparateur; variantes métier qui gardent la distinction flux, exposition et net. Peut composer des statistiques, sans imposer le markup actuel de `StatCard`. |
| P3 | `Ui::IconComponent` | Chevrons, croix, flèches et points des menus répétés dans les vues et composants. Catalogue limité aux icônes communes; conserver `TransactionIconService` pour les icônes métier. |

Les chemins abrégés de ces tableaux partent de `app/views` et portent le suffixe `.html.erb`.

## 3. Composants métier à extraire

Ces blocs ont leurs propres états et logique de présentation. Leur extraction est justifiée même avec un seul appel dans une page, particulièrement pour tester les variantes.

| Domaine | Composants proposés | Sources et responsabilité |
|---|---|---|
| Comptes — P2 | `Accounts::RowComponent`, `ArchivedRowComponent`, `GoalSummaryComponent` | `_account_row:1` instancie `GoalProgress` et gère le signe, le solde et la jauge; `index:64` affiche état archivé/réactivation; `show:73` résume un objectif lié. Injecter les données préparées et éviter des requêtes par ligne. |
| Comptes — P2 | `Accounts::BalanceAdjustmentComponent` | `_form:46` : écart et choix recalibrer/revenu/corriger avec targets et aide contextuelle. |
| Objectifs — P1/P2 | `Goals::CardComponent`, `HeroComponent`, `RhythmComponent` | `_goal_card:1`, `show:30`, `show:46`. Montants, cible absente, progression, objectif atteint, estimation/rythme. Réutiliser `GoalProgress` plutôt que recopier ses calculs dans un composant. |
| Dettes — P1/P2 | `Debts::RelationRowComponent`, `RelationHeroComponent`, `ClosedRowComponent`, `ClosedStateComponent`, `ScheduleComponent` | `_relation_row:1`; `show:39`, `:71`, `:92`, `:107`; `index:86`. États simple/double sens, abandon/clôture, regroupement par personne, calendrier et lien avec le budget. Mutualiser les actions compensation/réactivation via un petit bloc avec slot si utile. |
| Budget — P2 | `Budgets::MonthNavigationComponent`, `SummaryComponent`, `SectionComponent` | `index:5`, `:39`, `:96` : navigation mensuelle, présentation plan/en cours/bilan, en-tête/total/vide d'une section. Continuer à utiliser `Budgets::EntryRowComponent` pour les lignes existantes. |
| Budget — P2 | `Budgets::VitalConfortComponent`, `UnplannedSectionComponent`, `CategoryHeroComponent` | `_vital_confort:1`, `_unplanned_section:1`, `categories/show:44`. Répartition/progressions, hors-plan, état de catégorie et rattachement à un parent. Partager la jauge/statut avec `EntryRowComponent`, sans rendre une ligne de liste à la place du hero. |
| Transactions — P2 | `Transactions::PhraseInputComponent` | `new:17` : saisie libre, dictée, aide, statut de lecture; préserver `form="transaction-form"` et sa position **hors** du frame rechargé. |
| Transactions — P2 | `Transactions::MovementHeroComponent`, `FactRowComponent` | `show:33`, `show:52` : présentation via `MovementRow`, icône, montant signé/modifiable, note; lignes catégorie/compte/date/dette avec variantes éditable, lien et statique. Ne pas remplacer ce détail par `TransactionItemComponent`. |
| Transactions — P2 | `Transactions::SearchComponent` | `home/show:65` : champ, effacement et contrat de recherche; état vide composable avec `EmptyStateComponent`. |
| Espaces — P2 | `Spaces::CardComponent`, `MemberComponent`, `MappingRowComponent` | `spaces/index:14` et `:32` dupliquent la carte active/inactive; `members/index:14` et `:33` déclinent membres/invitations; `mappings/index:19` et `:46` déclinent alias/mots-clés. |
| Onboarding — P3 | `Onboarding::StepHeaderComponent` | Les trois `onboarding/*/show` répètent l'en-tête d'étape et la structure de contenu. Les champs, cartes, lignes de compte, progression et CTA sont déjà largement composants. |

### Analyses — P1 pour la décomposition, P2 pour les primitives

`app/views/analytics/index.html.erb` concentre 408 lignes avec calculs d'affichage, conditions et graphiques. Découpage recommandé :

- `Analytics::PeriodSelectorComponent` : ligne 20, périodes et bornes personnalisées; compose le switcher adapté et les champs/bouton existants.
- `Analytics::SpendingSummaryComponent` : ligne 46, montant, comparaison, plan et verdict. Extraire les présentations de comparaison et la barre avec repère proratisé.
- `Analytics::SpendingSplitComponent` : ligne 110, essentiel/plaisir/non classé. Partager une primitive de répartition avec Vital/Confort, sans fusionner leurs règles métier.
- `Analytics::RhythmChartComponent` : ligne 149, unités, pic et futur; ce n'est pas une jauge de progression.
- `Analytics::OverrunRowComponent` : `_overrun_row:1`; composant de section pour la liste, son compteur et son repli (index ligne 182).
- `Analytics::WithinPlanComponent` et `OffPlanComponent` : lignes 209 et 238, listes repliables, totaux et actions. Extraire une ligne compacte si les variantes restent lisibles.
- `Analytics::DebtSummaryComponent` et `RelationRowComponent` : ligne 271, paires de totaux, net et barres relatives au maximum.
- `Analytics::SavingsHistoryComponent` : ligne 328, série de trois mois et séquence d'épargne.
- `Goals::CardComponent` avec variante analytique, ou `Analytics::GoalRowComponent` : ligne 350, cible et estimation d'arrivée.
- `Analytics::AccountDistributionComponent` : ligne 372, répartition et trois premiers comptes.

Les agrégations et règles financières doivent rester dans les objets `Analyses::*`, `GoalProgress` ou un présentateur. Un ViewComponent ne doit pas devenir un nouveau service de calcul financier ni charger ses propres collections.

## 4. Administration — P2, thème distinct à préserver

L'administration possède `admin-btn`, `admin-input`, `admin-tabs`, `admin-badge`, `admin-table`, etc. Ajouter `classes: "admin-btn"` au bouton public ne suffit pas : il conserve ses classes `btn-*`. Choisir des variantes de thème explicites ou des composants `Admin::*` qui partagent les primitives adaptées.

| Extraction | Emplacements |
|---|---|
| `Admin::PageHeaderComponent`, `FilterBarComponent` | En-têtes des pages admin; recherches dans `users/index:6`, `spaces/index:6`, `transactions/index:6`, `taxonomy_nodes/index:7`, `shared/review_list:7`, `learned_aliases/dictionary:7`; filtres dans `quick_entry_attempts/index:6`. |
| Switcher adapté / `Admin::TabsComponent` | `corrections/index:9`, `taxonomy_nodes/index:15`, `shared/review_list:15`, `learned_aliases/dictionary:15`. |
| Boutons/champs thémés | `taxonomy_nodes/_form`, `_node_row_form`, `corrections/_correction_row`, `shared/_learned_row`, `learned_aliases/dictionary`, `category_gaps/index`, filtres et recherches. Les selects groupés ont la même limite d'API que les mappings publics. |
| `Admin::PaginationComponent` | `shared/_pagination:1`, déjà mutualisé en partial : convertir pour tester liens, paramètres et limites de page. |
| `Admin::TransactionsTableComponent`, `AttemptsTableComponent` | `shared/_transactions_table:1`, `_attempts_table:1`, avec empty state. Éviter un méga-composant de table universelle pour tous les tableaux admin. |
| `Admin::CorrectionRowComponent`, `LearnedRowComponent` | `corrections/_correction_row:1`, `shared/_learned_row:1` : variantes, formulaires, actions et états de revue. |
| `Admin::TaxonomyNodeComponent`, `TaxonomyNodeFormComponent`, `DictionaryEntryComponent` | `taxonomy_nodes/_node_row:1`, `_node_row_form:1`, `learned_aliases/dictionary:27`. Contrats de tri/arbre et éditions en ligne à préserver. |
| `Admin::StatCardComponent` ou variante thémée de `Ui::StatCardComponent` | `dashboard/show:75` et `:93`. Certaines valeurs sont des comptes, pas de l'argent : `Ui::StatCardComponent` formate systématiquement avec `money`. |
| `Admin::NavigationComponent` | `layouts/admin:18`, barre de navigation et compteurs. |

Les appels `button_to` (approbation, suppression, impersonation, etc.) doivent conserver leur vrai formulaire HTTP. `Ui::ButtonComponent` ne propose pas aujourd'hui de mode `button_to` : le remplacer par un lien Turbo modifierait son contrat. Ajouter ce mode ou garder le formulaire autour du bouton composant.

## 5. Marketing, widgets partagés et contenu statique

- **P2 — Marketing::NavigationComponent et FooterComponent** : navigation dans `landing/show:28`, `landing/guide:13`, `landing/guide_thanks:8`; pieds de page dans `show:327`, `guide:150`, `guide_thanks:72`.
- **P2 — Marketing::LocalePickerComponent** : `landing/show:36`. Le choix combine pays/langue/devise, ce n'est pas le simple `Navigation::LanguageSwitcherComponent`.
- **P2 — Marketing::CalculatorComponent et DiagnosticComponent** : `landing/show:177` et `:114`. Widgets autonomes avec contrôleurs, états et textes dynamiques. Le champ du calculateur est côté client, sans builder Rails : ne pas le forcer dans `InputFieldComponent` tel quel.
- **P2/P3 — Marketing::FeatureCardComponent, GuideStepComponent, SectionHeaderComponent** : répétitions à `landing/show:234`, `guide:77`, `guide_thanks:36` et introductions des sections. Les cards pédagogiques (`show:161`), projections (`show:205`) et aperçus de transaction (`show:87`) peuvent suivre si le bénéfice de variantes/tests est réel. Les transactions de démonstration ne sont pas des modèles `Transaction`.
- **P2 — Boutons marketing** : `landing-btn-*`, CTA de navigation et téléchargement répétés dans les trois pages. Étendre le thème du bouton ou créer `Marketing::ButtonComponent`; préserver attributs de téléchargement, ancres et tracking.
- **P2 — Pwa::InstallBannerComponent, Privacy::ConsentBannerComponent** : `shared/_pwa_install_banner:1`, `_meta_consent:5`. Widgets de décision complets; ne pas les assimiler à des flashes.
- **P3 — Admin::ImpersonationBannerComponent, Auth::VerificationHintComponent** : `shared/_impersonation_banner:1`, `auth/verifications/show:6`. Le second peut composer une nouvelle primitive de message informatif; `FlashMessageComponent` a un contrat de collection de flashes.
- **P3 — Ui::BadgeComponent / variantes métier** : `goals_helper.rb:34`, `admin_helper.rb:51`, badges membres/états. Les petits helpers de balise restent acceptables; extraction utile si l'on centralise réellement variantes et accessibilité.

## 6. Ce qu'il ne faut pas convertir systématiquement

- Les layouts, enveloppes de page, `form_with`, `turbo_frame_tag`, scripts d'intégration, balises de métadonnées et réponses Turbo Stream peuvent rester des vues/partials.
- `shared/_posthog`, `_meta_pixel`, `_turnstile` sont déjà de petits points d'intégration; leur transformation en ViewComponent n'est pas prioritaire.
- Les quatre pages juridiques et les templates email sont essentiellement du contenu statique. Pas de bénéfice établi à transformer chaque section/paragraphe en composant. Une enveloppe légale partagée est possible mais facultative.
- Les vues Devise de connexion/inscription/mot de passe ne sont pas les routes d'authentification actuelles (`devise_for ... skip: :all`, routes `Auth::*`). Vérifier leur utilité avant tout investissement. Leur partial d'erreurs reste utilisé dans le parcours actif.
- `LocaleHelper#language_links` reproduit le sélecteur de langue, mais aucun appel trouvé dans `app` : candidat au nettoyage, pas écart visible en production.
- `TransactionItemComponent`, `Budgets::EntryRowComponent`, les FAB, les headers de détail, les flashes, les pickers et une grande partie de l'onboarding sont déjà réutilisés. Aucun remplacement général nécessaire dans ces zones.
- Ne pas créer un composant uniquement parce qu'un `div`, un lien de texte ou un SVG existe. Les critères retenus sont duplication, états propres, contrat interactif ou logique de présentation substantielle.

## 7. Ordre conseillé et vérification de la future migration

1. Migrer les 11 actions directement compatibles, email/OTP et dates ordinaires; corriger les limites d'API des champs nécessaires à ces usages.
2. Extraire montant, menu d'actions, choix segmentés, cartes radio, récurrence et interrupteur.
3. Mutualiser erreurs, groupes de transactions/pagination, jauges et états vides.
4. Extraire les composants métier objectifs/dettes/comptes et décomposer les analyses.
5. Traiter administration, marketing et extractions facultatives.

Pour chaque lot : previews des variantes, specs de rendu qui vérifient les vrais contrats (noms/valeurs soumis, erreurs, URLs/méthodes, ARIA), puis tests système ciblés des interactions Stimulus/Turbo et inspection visuelle mobile. Vérifier en particulier les cartes booléennes, les CTA activés après saisie, les dates masquées, les montants zéro/sans cible/dépassés et la préservation des formulaires pendant le picker. Préserver les traductions : les `t('.clé')` des vues changent de portée une fois déplacés dans un composant.

## 8. État au 17 septembre 2026

Réalisé : sections 1, 2, 3, 5 et 6 (hors administration). Chaque composant a un spec et une preview. Le montant héro (`Forms::AmountFieldComponent`) porte lui-même le champ numérique et la normalisation entier/décimal. Les partials devenus de simples délégations vers un composant sont supprimés ; `Ui::IconComponent`, `Ui::BadgeComponent` et `Ui::RevertPromptComponent` couvrent les glyphes, badges et blocs « revenir en arrière » répétés. Les vues Devise mortes, `Ui::CommitmentCardComponent` et `LocaleHelper#language_links` sont retirés. Les quatre questions du profil d'onboarding passent par le picker (`Onboarding::ProfileSetups::PickerFieldComponent`) au lieu d'un select.

Reste à faire : la section 4 (administration) est volontairement laissée pour un lot ultérieur.
