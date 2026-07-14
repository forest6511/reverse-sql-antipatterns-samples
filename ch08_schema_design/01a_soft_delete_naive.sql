-- 素の UNIQUE(email): 論理削除後に同じ email で再登録できない
DROP TABLE IF EXISTS users_naive;
CREATE TABLE users_naive (
    id bigserial PRIMARY KEY,
    email text UNIQUE NOT NULL,
    deleted_at timestamptz
);
INSERT INTO users_naive (email) VALUES ('a@example.com');
-- 論理削除（行は残す）
UPDATE users_naive SET deleted_at = now() WHERE email = 'a@example.com';
-- 同じ email で再登録を試みる → 失敗するはず
INSERT INTO users_naive (email) VALUES ('a@example.com');
