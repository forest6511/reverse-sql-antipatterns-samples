-- 第5章 5節: 日付を文字列で持つと範囲検索・ソートが誤る（PostgreSQL 18）
-- 実行: scripts/pg.sh ch05_data_representation/05_date_as_string.sql

-- アンチ: text 列にゼロ埋め不揃いの日付
DROP TABLE IF EXISTS events_str;
CREATE TABLE events_str (
    id bigserial PRIMARY KEY,
    event_date text
);
INSERT INTO events_str (event_date) VALUES
    ('2026-07-9'), ('2026-07-10'), ('2026-07-13'),
    ('2026-7-13'), ('2026-12-1');

-- 7月分を範囲検索 → 2件しか返らない（ゼロ埋め不揃いが辞書順で漏れる）
SELECT event_date FROM events_str
WHERE event_date >= '2026-07-01' AND event_date <= '2026-07-31'
ORDER BY event_date;

-- 正: date 型 → 4件、正規化表示・日付順
DROP TABLE IF EXISTS events_d;
CREATE TABLE events_d (
    id bigserial PRIMARY KEY,
    event_date date
);
INSERT INTO events_d (event_date) VALUES
    ('2026-07-9'), ('2026-07-10'), ('2026-07-13'),
    ('2026-7-13'), ('2026-12-1');

SELECT event_date FROM events_d
WHERE event_date >= '2026-07-01' AND event_date <= '2026-07-31'
ORDER BY event_date;
