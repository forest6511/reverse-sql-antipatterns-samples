-- SET NOT NULL は ACCESS EXCLUSIVE で全行スキャン（約130ms・実行ごとに揺れる）
\timing on
ALTER TABLE mig_events ADD COLUMN memo text;          -- 一瞬
UPDATE mig_events SET memo = 'x';                      -- 埋める
ALTER TABLE mig_events ALTER COLUMN memo SET NOT NULL; -- 約130ms・全行スキャン
