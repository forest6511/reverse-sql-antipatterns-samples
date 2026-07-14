-- 第2章 PostgreSQL 18 — インデックスが使われないアンチパターン
-- 実行: docker compose exec -T pg psql -U app -d app < ch02_index_not_used/pg.sql

\echo '### 準備: email に通常の B-tree index を張る'
CREATE INDEX users_email_idx ON users (email);

\echo '### DEMO 1-anti: WHERE lower(email)=... （関数適用で index が効かない）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE lower(email) = 'user5000@example.com';

\echo '### DEMO 1-fixed: 式インデックスを張る'
CREATE INDEX users_lower_email_idx ON users (lower(email));
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE lower(email) = 'user5000@example.com';
DROP INDEX users_lower_email_idx;

\echo '### DEMO 1b-anti: date(created_at)=特定日（関数適用で index が効かない）'
CREATE INDEX orders_created_at_idx ON orders (created_at);
ANALYZE orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, amount FROM orders WHERE date(created_at) = '2026-04-19';

\echo '### DEMO 1b-fixed: 範囲で書けば index が効く'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, amount FROM orders
WHERE created_at >= '2026-04-19' AND created_at < '2026-04-20';
DROP INDEX orders_created_at_idx;

\echo '### DEMO 2-anti: LIKE ''prefix%'' 前方一致（非Cロケールでは B-tree が効かない）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE email LIKE 'user5000@%';

\echo '### DEMO 2-fixed: text_pattern_ops の index を張ると前方一致が効く'
CREATE INDEX users_email_pat_idx ON users (email text_pattern_ops);
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE email LIKE 'user5000@%';
DROP INDEX users_email_pat_idx;

\echo '### DEMO 3-anti: LIKE ''%mid%'' 中間一致（B-tree では原理的に効かない）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE email LIKE '%user5000@%';

\echo '### DEMO 3-fixed: pg_trgm の GIN index で中間一致を速く'
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX users_email_trgm_idx ON users USING gin (email gin_trgm_ops);
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE email LIKE '%user5000@%';
DROP INDEX users_email_trgm_idx;

DROP INDEX users_email_idx;

\echo '### DEMO 4: JSONB を @> で検索（GIN index の有無）'
CREATE TABLE events (
    id      bigserial PRIMARY KEY,
    payload jsonb NOT NULL
);
INSERT INTO events (payload)
SELECT jsonb_build_object(
    'type', (ARRAY['click','view','purchase','signup'])[1 + (g % 4)],
    'user_id', 1 + (g % 100000)
)
FROM generate_series(1, 200000) g;
ANALYZE events;

\echo '### DEMO 4-anti: payload @> ''{"user_id": 42}'' に index なし → Seq Scan'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM events WHERE payload @> '{"user_id": 42}';

\echo '### DEMO 4-fixed: GIN index を張る'
CREATE INDEX events_payload_gin ON events USING gin (payload);
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM events WHERE payload @> '{"user_id": 42}';

\echo '### 後片付け'
DROP TABLE events;
