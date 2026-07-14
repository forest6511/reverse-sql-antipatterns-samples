-- 第1章 PostgreSQL 18 — N+1 と重い JOIN、過剰取得
-- 実行: docker compose exec -T pg psql -U app -d app < ch01_nplus1_join/pg.sql

\echo '### DEMO A-before: N+1 の内側1本（user_id に index なし）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, amount, status FROM orders WHERE user_id = 6;

\echo '### index 作成'
CREATE INDEX orders_user_id_idx ON orders (user_id);

\echo '### DEMO A-after: N+1 の内側1本（index あり）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, amount, status FROM orders WHERE user_id = 6;

\echo '### DEMO B: 一覧のユーザー20件（外側の1本）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM users WHERE status = 'active' ORDER BY id LIMIT 20;

\echo '### DEMO C: N+1 を JOIN 1本にまとめる（IN で20人に絞る）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.id, u.email, o.id AS order_id, o.amount
FROM users u JOIN orders o ON o.user_id = u.id
WHERE u.id IN (SELECT id FROM users WHERE status = 'active' ORDER BY id LIMIT 20);

\echo '### DEMO C2: アプリ側JOIN の代わりに DB の Hash Join（active × paid）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.id, u.email, o.amount
FROM users u JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active' AND o.status = 'paid';

\echo '### DEMO D-anti: 過剰取得（DISTINCT で JOIN の重複を消す）'
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT u.id, u.email
FROM users u JOIN orders o ON o.user_id = u.id
WHERE o.status = 'paid';

\echo '### DEMO D-fixed: EXISTS に書き換え'
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.id, u.email
FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.status = 'paid'
);

\echo '### DEMO E-anti: SELECT * は Index Only Scan を妨げる（直近30日100件）'
CREATE INDEX orders_created_at_idx ON orders (created_at);
-- 可視性マップを確定させる（Index Only Scan の Heap Fetches を安定させる）
VACUUM (ANALYZE) orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE created_at >= now() - interval '30 days'
ORDER BY created_at DESC LIMIT 100;

\echo '### DEMO E-fixed: 必要な列だけ + カバリング index（Index Only Scan）'
DROP INDEX orders_created_at_idx;
CREATE INDEX orders_created_at_cover_idx
    ON orders (created_at DESC) INCLUDE (id, amount);
-- カバリング index の Heap Fetches: 0 を再現するため可視性マップを確定
VACUUM (ANALYZE) orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, amount, created_at FROM orders
WHERE created_at >= now() - interval '30 days'
ORDER BY created_at DESC LIMIT 100;
DROP INDEX orders_created_at_cover_idx;

\echo '### 後片付け: 作成した index を削除して初期状態へ戻す'
DROP INDEX IF EXISTS orders_user_id_idx;
