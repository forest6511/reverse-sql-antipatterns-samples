-- CREATE INDEX は ShareLock（=SHARE）を取り、書き込み(RowExclusiveLock)をブロック。
-- 別セッションで以下を実行し、この INDEX ビルド中に INSERT が待たされることを確認する。
--   SET lock_timeout='2s';
--   INSERT INTO mig_events(id,user_id,payload,memo) VALUES (9999999,1,'z','z');
--   → ERROR: canceling statement due to lock timeout
BEGIN;
CREATE INDEX mig_idx_lock ON mig_events(user_id);
SELECT mode, granted FROM pg_locks
WHERE relation = 'mig_events'::regclass AND mode = 'ShareLock';  -- ShareLock / t
SELECT pg_sleep(8);
ROLLBACK;

-- CONCURRENTLY はトランザクション外専用。書き込みをブロックしない。
-- （別セッションの INSERT は成功する）
-- ERROR: CREATE INDEX CONCURRENTLY cannot run inside a transaction block
CREATE INDEX CONCURRENTLY mig_idx_conc ON mig_events(user_id);
