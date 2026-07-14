-- ADD COLUMN: constant default（書き換えなし・1ms）vs volatile default（全書き換え・635ms）
\timing on
-- (A) constant default: メタデータのみ、81MB のまま
--     本文の解決策と主題列を揃えるため created_c（定数）で計測する
ALTER TABLE mig_events ADD COLUMN created_c timestamptz DEFAULT '2026-01-01 00:00:00+09';
SELECT pg_size_pretty(pg_relation_size('mig_events')) AS size_after_const;  -- 81 MB

-- (B) volatile default: テーブル全書き換え、81MB→97MB
ALTER TABLE mig_events ADD COLUMN created_v timestamptz DEFAULT clock_timestamp();
SELECT pg_size_pretty(pg_relation_size('mig_events')) AS size_after_volatile;  -- 97 MB
