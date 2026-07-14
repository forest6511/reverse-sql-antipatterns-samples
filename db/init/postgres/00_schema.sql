-- 逆引きSQLアンチパターン — PostgreSQL 18 共通スキーマ
--
-- 本書の多くの章が使う土台テーブル。行数を十分に大きく取り、
-- Seq Scan と Index Scan の差がミリ秒で観測できるようにする。
--
-- ここでは「あえてインデックスを張らない」。各章で
-- 「index が無いから Seq Scan」→「index を張ると Index Scan」の
-- Before/After を実機で見せるため、初期状態は素のテーブルにする。
--
-- 【再現性】乱数は setseed で固定し、created_at は now() ではなく
-- 固定基点 '2026-07-01' からの相対にする。これにより、誰がいつ
-- この環境を作っても、本書に載せた EXPLAIN の値・境界値が同じ
-- 行・同じ順序で再現する（本書の数値は実測値であり、かつ手元で
-- 追試できることを担保する）。

-- ── users: 10万人 ──────────────────────────────────────────
CREATE TABLE users (
    id          bigserial PRIMARY KEY,
    email       text        NOT NULL,
    status      text        NOT NULL,   -- 'active' / 'inactive' / 'banned'
    created_at  timestamptz NOT NULL
);

-- ── orders: 100万件（1ユーザーあたり平均10件）────────────────
CREATE TABLE orders (
    id          bigserial PRIMARY KEY,
    user_id     bigint      NOT NULL,
    amount      integer     NOT NULL,   -- 金額は「円」を整数で保持（05章で理由を示す）
    status      text        NOT NULL,   -- 'pending' / 'paid' / 'shipped' / 'cancelled'
    created_at  timestamptz NOT NULL
);

-- ── seed: users 10万件 ─────────────────────────────────────
-- 乱数シードを固定（この直後の random() が決定的になる）
SELECT setseed(0.42);
INSERT INTO users (email, status, created_at)
SELECT
    'user' || g || '@example.com',
    (ARRAY['active','active','active','inactive','banned'])[1 + (g % 5)],
    -- 固定基点から過去2年に散らす（now() は使わない）
    TIMESTAMPTZ '2026-07-01 00:00:00+09' - (random() * interval '730 days')
FROM generate_series(1, 100000) AS g;

-- ── seed: orders 100万件 ───────────────────────────────────
-- orders 用に別のシードを固定する
SELECT setseed(0.13);
INSERT INTO orders (user_id, amount, status, created_at)
SELECT
    1 + (random() * 99999)::bigint,
    (100 + random() * 49900)::integer,          -- 100〜50000円
    (ARRAY['pending','paid','paid','shipped','cancelled'])[1 + (g % 5)],
    TIMESTAMPTZ '2026-07-01 00:00:00+09' - (random() * interval '730 days')
FROM generate_series(1, 1000000) AS g;

-- 統計情報を更新（プランナが正しい行数見積もりを出せるように）
ANALYZE users;
ANALYZE orders;
