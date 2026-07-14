-- FKなし: 親を消すと子が orphan record（親レコードがない行）に。JOINで除外され、集計が合わない
DROP TABLE IF EXISTS orders_nofk, users_nofk;
CREATE TABLE users_nofk (id bigint PRIMARY KEY, name text);
CREATE TABLE orders_nofk (id bigint PRIMARY KEY, user_id bigint, amount int);
INSERT INTO users_nofk VALUES (1,'alice'),(2,'bob');
INSERT INTO orders_nofk VALUES (10,1,500),(11,2,300),(12,2,200);
-- bob(id=2)をFK制約なしで削除 → orders 11,12 が orphan record に
DELETE FROM users_nofk WHERE id = 2;

-- 全注文金額の合計（本来 500+300+200=1000）
SELECT sum(amount) AS total_all_orders FROM orders_nofk;
-- ユーザーと結合した集計（orphan record が除外されて 500 だけ）
SELECT sum(o.amount) AS total_joined
FROM orders_nofk o JOIN users_nofk u ON u.id = o.user_id;
-- orphan record の検出
SELECT o.id, o.user_id FROM orders_nofk o
LEFT JOIN users_nofk u ON u.id = o.user_id
WHERE u.id IS NULL;
