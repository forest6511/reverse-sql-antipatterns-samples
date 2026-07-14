-- 第6章 2節: 残高の Lost Update（read-modify-write）／PostgreSQL 18

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (id bigint PRIMARY KEY, balance int);
INSERT INTO accounts VALUES (1, 1000), (2, 1000);

-- ===== アンチ: 読んで計算して書き戻す（+100 が消える）=====
-- セッションA                        セッションB
-- BEGIN;
-- SELECT balance FROM accounts WHERE id=1;  -- A: 1000
--                                    BEGIN;
--                                    SELECT balance FROM accounts WHERE id=1; -- B: 1000
-- UPDATE accounts SET balance=1100 WHERE id=1;  -- A: 1000+100
-- COMMIT;
--                                    UPDATE accounts SET balance=1100 WHERE id=1; -- B: 1000+100
--                                    COMMIT;
-- => 最終 1100（期待 1200）

-- ===== 正: DB内で加算 =====
-- UPDATE accounts SET balance=1000 WHERE id=1;  -- reset
-- セッションA                        セッションB
-- BEGIN;
-- UPDATE accounts SET balance=balance+100 WHERE id=1;  -- A
--                                    BEGIN;
--                                    UPDATE accounts SET balance=balance+100 WHERE id=1; -- B待ち
-- COMMIT;
--                                    COMMIT;
-- => 最終 1200
