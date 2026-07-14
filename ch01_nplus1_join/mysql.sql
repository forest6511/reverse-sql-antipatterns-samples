-- 第1章 MySQL 8.4 — N+1 と重い JOIN、過剰取得
-- 実行: docker compose exec -T mysql mysql -uroot -proot app < ch01_nplus1_join/mysql.sql

SELECT '### DEMO A-before: N+1 の内側1本（user_id に index なし）' AS step;
EXPLAIN ANALYZE
SELECT id, amount, status FROM orders WHERE user_id = 6;

SELECT '### index 作成' AS step;
CREATE INDEX orders_user_id_idx ON orders (user_id);

SELECT '### DEMO A-after: N+1 の内側1本（index あり）' AS step;
EXPLAIN ANALYZE
SELECT id, amount, status FROM orders WHERE user_id = 6;

SELECT '### DEMO C: N+1 を JOIN 1本にまとめる（20人に絞る）' AS step;
EXPLAIN ANALYZE
SELECT u.id, u.email, o.id AS order_id, o.amount
FROM users u JOIN orders o ON o.user_id = u.id
WHERE u.id IN (
    SELECT id FROM (
        SELECT id FROM users WHERE status = 'active' ORDER BY id LIMIT 20
    ) t
);

SELECT '### 後片付け: 作成した index を削除して初期状態へ戻す' AS step;
DROP INDEX orders_user_id_idx ON orders;
