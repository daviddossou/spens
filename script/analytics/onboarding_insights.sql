-- Onboarding insights straight from the database. Read-only.
-- "fs" = each non-admin user's first own space: the one that describes the person.
CREATE TEMP VIEW fs AS
SELECT DISTINCT ON (s.user_id) s.*, u.created_at AS signed_up_at, u.acquisition
FROM spaces s JOIN users u ON u.id = s.user_id
WHERE NOT u.admin
ORDER BY s.user_id, s.created_at;

\echo '== 1. Where everyone stands in onboarding'
SELECT COALESCE(onboarding_current_step, '(never started)') AS step, COUNT(*) AS users,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM fs GROUP BY 1 ORDER BY users DESC;

\echo '== 2. Completion rate by sign-up week'
SELECT date_trunc('week', signed_up_at)::date AS week, COUNT(*) AS signups,
       COUNT(*) FILTER (WHERE onboarding_current_step = 'onboarding_completed') AS onboarded,
       ROUND(100.0 * COUNT(*) FILTER (WHERE onboarding_current_step = 'onboarding_completed') / COUNT(*), 1) AS pct
FROM fs GROUP BY 1 ORDER BY 1 DESC LIMIT 12;

\echo '== 3. Completion rate by acquisition source'
SELECT COALESCE(acquisition->>'utm_source', '(direct)') AS source, COUNT(*) AS signups,
       ROUND(100.0 * COUNT(*) FILTER (WHERE onboarding_current_step = 'onboarding_completed') / COUNT(*), 1) AS pct_onboarded
FROM fs GROUP BY 1 ORDER BY signups DESC;

\echo '== 4. Problems chosen'
SELECT goal, COUNT(*) AS users,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fs WHERE jsonb_array_length(financial_goals) > 0), 1) AS pct_of_answerers
FROM fs, jsonb_array_elements_text(financial_goals) AS goal
GROUP BY 1 ORDER BY users DESC;

\echo '== 5. How many problems each user ticks'
SELECT jsonb_array_length(financial_goals) AS problems, COUNT(*) AS users
FROM fs WHERE jsonb_array_length(financial_goals) > 0 GROUP BY 1 ORDER BY 1;

\echo '== 6. Problems that go together (top pairs)'
SELECT a.goal AS goal_a, b.goal AS goal_b, COUNT(*) AS users
FROM fs, jsonb_array_elements_text(financial_goals) AS a(goal), jsonb_array_elements_text(financial_goals) AS b(goal)
WHERE a.goal < b.goal GROUP BY 1, 2 ORDER BY users DESC LIMIT 10;

\echo '== 7. Problems by country (top countries)'
SELECT country, goal, COUNT(*) AS users
FROM fs, jsonb_array_elements_text(financial_goals) AS goal
WHERE country IN (SELECT country FROM fs WHERE country IS NOT NULL GROUP BY 1 ORDER BY COUNT(*) DESC LIMIT 5)
GROUP BY 1, 2 ORDER BY country, users DESC;

\echo '== 8. Who they are'
SELECT 'country' AS field, country AS value, COUNT(*) FROM fs WHERE country IS NOT NULL GROUP BY 2
UNION ALL SELECT 'currency', currency, COUNT(*) FROM fs WHERE onboarding_current_step = 'onboarding_completed' GROUP BY 2
UNION ALL SELECT 'income_frequency', COALESCE(NULLIF(income_frequency, ''), '(blank)'), COUNT(*) FROM fs WHERE country IS NOT NULL GROUP BY 2
UNION ALL SELECT 'main_income_source', COALESCE(NULLIF(main_income_source, ''), '(blank)'), COUNT(*) FROM fs WHERE country IS NOT NULL GROUP BY 2
ORDER BY field, count DESC;

\echo '== 9. Accounts opened during onboarding (names created within 10 min of the first one)'
WITH first_acc AS (SELECT space_id, MIN(created_at) AS t0 FROM accounts GROUP BY 1)
SELECT a.name, COUNT(*) AS spaces
FROM accounts a JOIN first_acc f USING (space_id) JOIN fs ON fs.id = a.space_id
WHERE a.created_at <= f.t0 + interval '10 minutes'
GROUP BY 1 HAVING COUNT(*) >= 2   -- names used once are personal: left out
ORDER BY spaces DESC LIMIT 15;

\echo '== 10. Does the problem predict usage? Per problem: onboarded users, share with a real transaction, share active in the last 30 days'
WITH real_tx AS (
  SELECT t.space_id, COUNT(*) AS n, MAX(t.created_at) AS last_at
  FROM transactions t JOIN transaction_types tt ON tt.id = t.transaction_type_id
  WHERE tt.kind <> 'initial_balance' GROUP BY 1)
SELECT goal, COUNT(*) AS onboarded,
       ROUND(100.0 * COUNT(*) FILTER (WHERE r.n > 0) / COUNT(*), 1) AS pct_with_real_tx,
       ROUND(100.0 * COUNT(*) FILTER (WHERE r.last_at > now() - interval '30 days') / COUNT(*), 1) AS pct_active_30d,
       ROUND(AVG(COALESCE(r.n, 0)), 1) AS avg_tx
FROM fs CROSS JOIN LATERAL jsonb_array_elements_text(fs.financial_goals) AS goal
LEFT JOIN real_tx r ON r.space_id = fs.id
WHERE fs.onboarding_current_step = 'onboarding_completed'
GROUP BY 1 ORDER BY onboarded DESC;

\echo '== 11. Problem-to-feature match: did they reach the feature built for their problem?'
SELECT m.goal, m.feature, COUNT(*) AS users_with_problem,
       COUNT(*) FILTER (WHERE m.reached) AS reached,
       ROUND(100.0 * COUNT(*) FILTER (WHERE m.reached) / COUNT(*), 1) AS pct
FROM (
  SELECT g.goal, x.feature, x.reached
  FROM fs CROSS JOIN LATERAL jsonb_array_elements_text(fs.financial_goals) AS g(goal)
  CROSS JOIN LATERAL (VALUES
    ('pay_off_debt',          'a debt',           EXISTS (SELECT 1 FROM debts d WHERE d.space_id = fs.id)),
    ('track_repayments',      'a debt',           EXISTS (SELECT 1 FROM debts d WHERE d.space_id = fs.id)),
    ('save_regularly',        'a savings goal',   EXISTS (SELECT 1 FROM goals go WHERE go.space_id = fs.id)),
    ('cut_wasteful_spending', 'a budget line',    EXISTS (SELECT 1 FROM budget_items b WHERE b.space_id = fs.id)),
    ('track_all_accounts',    '2+ accounts',      (SELECT COUNT(*) FROM accounts a WHERE a.space_id = fs.id) >= 2),
    ('track_spending',        '5+ expenses',      (SELECT COUNT(*) FROM transactions t JOIN transaction_types tt ON tt.id = t.transaction_type_id
                                                   WHERE t.space_id = fs.id AND tt.kind = 'expense') >= 5)
  ) AS x(goal, feature, reached)
  WHERE x.goal = g.goal AND fs.onboarding_current_step = 'onboarding_completed'
) m GROUP BY 1, 2 ORDER BY pct;

\echo '== 12. Activation milestones by problem (share of onboarded users with that problem)'
SELECT goal, am.name AS milestone, COUNT(DISTINCT fs.user_id) AS users
FROM fs CROSS JOIN LATERAL jsonb_array_elements_text(fs.financial_goals) AS goal
JOIN activation_milestones am ON am.user_id = fs.user_id
GROUP BY 1, 2 ORDER BY goal, users DESC;

\echo '== 13. People stuck mid-onboarding for more than a day (to contact)'
SELECT u.email, fs.onboarding_current_step AS stuck_at, fs.signed_up_at::date, fs.financial_goals
FROM fs JOIN users u ON u.id = fs.user_id
WHERE COALESCE(fs.onboarding_current_step, '') <> 'onboarding_completed' AND fs.signed_up_at < now() - interval '1 day'
ORDER BY fs.signed_up_at DESC LIMIT 50;
