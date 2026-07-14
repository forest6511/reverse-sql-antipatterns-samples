-- 第3章 MySQL 8.4 — 深いOFFSETページネーション
-- 実行: docker compose exec -T mysql mysql -uroot -proot app < ch03_offset_pagination/mysql.sql
--
-- MySQL の LIMIT は「LIMIT offset, count」または「LIMIT count OFFSET offset」。
-- EXPLAIN ANALYZE で actual time を出す（PostgreSQL とは書式が異なる）。

SELECT '### 準備: created_at + id の複合 index を張る' AS msg;
CREATE INDEX orders_created_at_id_idx ON orders (created_at DESC, id DESC);
ANALYZE TABLE orders;

SELECT '=== DEMO 1: 浅いページ（1ページ目）===' AS msg;
EXPLAIN ANALYZE
SELECT id, user_id, amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 0\G

SELECT '=== DEMO 2-anti: 深いページ（OFFSET 999980）===' AS msg;
EXPLAIN ANALYZE
SELECT id, user_id, amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 999980\G

SELECT '=== DEMO 2-fixed-A(悪): row-value 比較は MySQL では index range にならない ===' AS msg;
SELECT id, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 999980
INTO @b_id, @b_created;
SELECT @b_created AS boundary_created, @b_id AS boundary_id;

-- (created_at, id) < (X, Y) は MySQL 8.4 だと Filter に落ちて全走査になる
EXPLAIN ANALYZE
SELECT id, user_id, amount, created_at
FROM orders
WHERE (created_at, id) < (@b_created, @b_id)
ORDER BY created_at DESC, id DESC
LIMIT 20\G

SELECT '=== DEMO 2-fixed-B(正): OR 展開すると index range scan で速い ===' AS msg;
-- MySQL では row-value を OR に展開してやると index range scan になる
EXPLAIN ANALYZE
SELECT id, user_id, amount, created_at
FROM orders
WHERE created_at < @b_created
   OR (created_at = @b_created AND id < @b_id)
ORDER BY created_at DESC, id DESC
LIMIT 20\G

SELECT '=== DEMO 3-anti: ORDER BY RAND() で全件ソート ===' AS msg;
EXPLAIN ANALYZE
SELECT id, user_id, amount
FROM orders
ORDER BY RAND()
LIMIT 10\G

SELECT '### 後片付け: index を DROP' AS msg;
DROP INDEX orders_created_at_id_idx ON orders;
