-- 第5章 2節: 時刻をタイムゾーンなしで持つと締め日がずれる（PostgreSQL 18）
-- 実行: scripts/pg.sh ch05_data_representation/02_timestamp_tz.sql

DROP TABLE IF EXISTS orders_ts;
CREATE TABLE orders_ts (
    id bigserial PRIMARY KEY,
    created_at timestamptz
);
-- JST 2026-07-13 08:30 の注文（UTC では 2026-07-12 23:30）
INSERT INTO orders_ts (created_at) VALUES ('2026-07-13 08:30:00+09');

-- アンチ: サーバTZ=UTC で「7/13の売上」を単純に切る → 0 行（前日に含まれる）
SET TimeZone = 'UTC';
SELECT id, created_at FROM orders_ts
WHERE created_at >= '2026-07-13' AND created_at < '2026-07-14';

-- 正: 境界を JST で明示 → 1 行ヒット
SELECT id, created_at FROM orders_ts
WHERE created_at >= '2026-07-13 00:00+09'
  AND created_at < '2026-07-14 00:00+09';
