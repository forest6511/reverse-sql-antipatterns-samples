-- 第7章 PostgreSQL 18 セットアップ: 100万件のテーブル
DROP TABLE IF EXISTS mig_events;
CREATE TABLE mig_events (
    id bigint PRIMARY KEY,
    user_id int NOT NULL,
    payload text NOT NULL
);
INSERT INTO mig_events
SELECT g, (g % 10000) + 1, repeat('x', 40)
FROM generate_series(1, 1000000) g;
VACUUM ANALYZE mig_events;
-- rows=1000000 / size=81 MB
