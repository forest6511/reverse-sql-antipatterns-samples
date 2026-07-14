-- 長時間トランザクションが「回収可能な最古XID」を固定し、autovacuum が進まなくなる再現。
-- セッションA:
BEGIN;
SELECT txid_current();  -- XID を割り当て
SELECT pg_sleep(60);    -- 放置（本番では commit/rollback 忘れ・分析クエリ長時間実行）
COMMIT;

-- セッションB: 回収を妨げている原因の接続を特定する
SELECT pid, state,
       age(backend_xmin) AS xmin_age,
       now() - xact_start AS xact_duration,
       left(query, 40) AS query
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC;
-- backend_xmin が古い（xmin_age が大きい）接続が VACUUM を妨げている原因。

-- XID wraparound が迫ると出る警告・エラー（公式・20億XID消費が必要なため引用）:
-- WARNING: database "app" must be vacuumed within 39985967 transactions
-- ERROR:   database is not accepting commands that assign new XIDs
--          to avoid wraparound data loss in database "app"
