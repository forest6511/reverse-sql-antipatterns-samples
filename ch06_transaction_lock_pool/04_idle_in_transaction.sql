-- 第6章 4節: トランザクション中の外部待ちで idle in transaction ／PostgreSQL 18

-- 準備
-- 土台の orders（100万件）の id=1 をそのまま使う。テーブルは作り直さない
-- （DROP して 1 行のデモ表に置き換えると土台が失われるため）。

-- ===== トラブルの観測 =====
-- セッションA: tx を開いたまま「外部API待ち」を模擬（放置）
-- BEGIN;
-- UPDATE orders SET status = 'paid' WHERE id=1;
-- （ここで外部APIの応答を待っている想定 = 何も実行しない）

-- 別セッションで観測:
SELECT state, wait_event_type, left(query, 40) AS query
FROM pg_stat_activity
WHERE state = 'idle in transaction';
-- => idle in transaction / Client / UPDATE orders SET status ...

SELECT count(*) AS total_conns,
       count(*) FILTER (WHERE state='idle in transaction') AS idle_in_tx
FROM pg_stat_activity WHERE datname='app';
-- => total_conns=2 / idle_in_tx=1（1接続を占有）

SHOW max_connections;   -- 既定 100

-- 保険: 放置 tx を DB 側で打ち切る
-- SET idle_in_transaction_session_timeout = '10s';

-- ===== 正 =====
-- 外部 I/O は tx の外に出し、DB 更新だけを短い tx で囲む:
-- （1）外部APIを呼ぶ（tx外）
-- （2）BEGIN; UPDATE orders SET status='paid' WHERE id=1; COMMIT;
