\timing off
DROP TABLE IF EXISTS orders09;
CREATE TABLE orders09 (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     bigint      NOT NULL,
    amount      numeric(10,2) NOT NULL,
    status      text        NOT NULL,
    created_at  timestamptz NOT NULL
);
-- 再現性のため乱数シードを固定（companion で同じ行が出る）
SELECT setseed(0.42);
INSERT INTO orders09 (user_id, amount, status, created_at)
SELECT (random()*100000)::bigint + 1,
       (random()*10000)::numeric(10,2),
       (ARRAY['paid','pending','cancelled'])[1+floor(random()*3)],
       now() - (random()*365) * interval '1 day'
FROM generate_series(1, 1000000);
ANALYZE orders09;
SELECT count(*) AS total_rows FROM orders09;
