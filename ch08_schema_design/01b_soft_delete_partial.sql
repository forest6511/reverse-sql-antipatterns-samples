-- 部分UNIQUE: 生きている行(deleted_at IS NULL)だけ一意にする
DROP TABLE IF EXISTS users_partial;
CREATE TABLE users_partial (
    id bigserial PRIMARY KEY,
    email text NOT NULL,
    deleted_at timestamptz
);
CREATE UNIQUE INDEX users_partial_email_active
    ON users_partial (email) WHERE deleted_at IS NULL;

INSERT INTO users_partial (email) VALUES ('a@example.com');
UPDATE users_partial SET deleted_at = now() WHERE email = 'a@example.com';
-- 論理削除済みなので、同じ email で再登録できる
INSERT INTO users_partial (email) VALUES ('a@example.com');
SELECT id, email, (deleted_at IS NOT NULL) AS deleted FROM users_partial ORDER BY id;

-- ただし、生きている行が2つになる登録は依然 NG
INSERT INTO users_partial (email) VALUES ('a@example.com');
