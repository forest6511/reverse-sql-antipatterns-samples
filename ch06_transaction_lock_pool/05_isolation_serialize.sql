-- 第6章 5節: 分離レベルを上げると serialization failure（40001）／PostgreSQL 18
-- accounts テーブルは 02 で作成済み想定。id=1, balance=1000 にリセットして開始。

-- ===== アンチ: REPEATABLE READ でリトライを用意しない =====
-- UPDATE accounts SET balance=1000 WHERE id=1;  -- reset
-- セッションA                        セッションB
-- BEGIN ISOLATION LEVEL REPEATABLE READ;
-- SELECT balance FROM accounts WHERE id=1;  -- A: 1000
--                                    BEGIN ISOLATION LEVEL REPEATABLE READ;
--                                    SELECT balance FROM accounts WHERE id=1; -- B: 1000
-- UPDATE accounts SET balance=1100 WHERE id=1;  -- A
-- COMMIT;
--                                    UPDATE accounts SET balance=1100 WHERE id=1;
--                                        -- B: ERROR 40001 could not serialize access
--                                        --    due to concurrent update -> ROLLBACK

-- SQLSTATE を確認するには B 側で \set VERBOSITY verbose:
--   ERROR:  40001: could not serialize access due to concurrent update

-- ===== 正: 40001 を捕まえてトランザクションをやり直す（擬似コード）=====
-- retry:
--   BEGIN ISOLATION LEVEL REPEATABLE READ;
--   ...処理...
--   COMMIT;
--   もし SQLSTATE 40001 なら ROLLBACK して retry へ
-- ※ 多くの Lost Update は 1・2 節のアトミック UPDATE / FOR UPDATE で足りる
