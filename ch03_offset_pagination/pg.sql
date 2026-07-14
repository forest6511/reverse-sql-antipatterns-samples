-- 第3章 PostgreSQL 18 — 深いOFFSETページネーション
-- 実行: docker compose exec -T pg psql -U app -d app < ch03_offset_pagination/pg.sql
--
-- 前提: orders 100万件。ページネーションは created_at 降順が定番。
-- 素のテーブルでは created_at に index が無いので、まず現実的に張る。

\echo '### 準備: created_at + id の複合 index を張る（ページネーションの土台）'
CREATE INDEX orders_created_at_id_idx ON orders (created_at DESC, id DESC);
ANALYZE orders;

\echo ''
\echo '=== DEMO 1: 浅いページ（1ページ目）は OFFSET でも速い ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 0;

\echo ''
\echo '=== DEMO 2-anti: 深いページ（5万ページ目 = OFFSET 999980）は遅くなる ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 999980;

\echo ''
\echo '=== DEMO 2-fixed: キーセット法（前ページ末尾の値で seek）==='
\echo '（前ページ末尾を created_at=X, id=Y と仮定。中間ページの1件を境界に使う）'
-- 5000ページ目末尾（OFFSET 100000）の境界値を取得（本文では「前ページの最後の行」）
-- ※ 最古行付近（OFFSET 999980）を境界にすると残り行が少なすぎて
--   Bitmap Heap Scan になり「直接ジャンプ」が見えないため、中間ページを使う。
SELECT id, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 100000 \gset boundary_

\echo '境界値:'
\echo :'boundary_created_at' / :'boundary_id'

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount, created_at
FROM orders
WHERE (created_at, id) < (:'boundary_created_at', :boundary_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;

\echo ''
\echo '=== DEMO 3-anti: ORDER BY random() で全件ソート ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount
FROM orders
ORDER BY random()
LIMIT 10;

\echo ''
\echo '=== DEMO 3-fixed: TABLESAMPLE でざっくり抽出（全ソート不要）==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount
FROM orders TABLESAMPLE SYSTEM (0.1)
LIMIT 10;

\echo ''
\echo '### 後片付け: index を DROP して初期状態に戻す'
DROP INDEX orders_created_at_id_idx;
