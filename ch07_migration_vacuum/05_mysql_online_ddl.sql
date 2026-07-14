-- MySQL 8.4 Online DDL: INSTANT（約3.6ms）vs COPY（約1,188ms・約330倍）
-- 前提: 00_setup_mysql.sql で mig_events 100万件を作っておくこと
-- (A) ADD COLUMN INSTANT: メタデータのみ、100万件でも即時
SELECT NOW(6) AS t0;
ALTER TABLE mig_events ADD COLUMN status_a INT NOT NULL DEFAULT 0,
  ALGORITHM=INSTANT;
SELECT NOW(6) AS t1;  -- 約3.6ms

-- (B) 列型変更に INSTANT を要求 → 即エラー（警告なくフォールバックしない＝事前検証に使える）
ALTER TABLE mig_events MODIFY COLUMN payload VARCHAR(200) NOT NULL,
  ALGORITHM=INSTANT;
-- ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported.
--   Reason: Need to rebuild the table to change column type. Try ALGORITHM=COPY/INPLACE.

-- (C) COPY（全行再構築・約1,188ms）
ALTER TABLE mig_events MODIFY COLUMN payload VARCHAR(200) NOT NULL,
  ALGORITHM=COPY, LOCK=SHARED;

-- (D) セカンダリインデックスは INPLACE LOCK=NONE で並行 DML 可（約499ms）
ALTER TABLE mig_events ADD INDEX idx_user (user_id),
  ALGORITHM=INPLACE, LOCK=NONE;
