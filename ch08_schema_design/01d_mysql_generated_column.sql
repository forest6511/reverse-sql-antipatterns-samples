DROP TABLE IF EXISTS users_gen_my;
CREATE TABLE users_gen_my (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    deleted_at DATETIME NULL,
    email_active VARCHAR(255)
      GENERATED ALWAYS AS (IF(deleted_at IS NULL, email, NULL)) VIRTUAL,
    UNIQUE KEY uq_email_active (email_active)
);
INSERT INTO users_gen_my (email) VALUES ('a@example.com');
UPDATE users_gen_my SET deleted_at = NOW() WHERE email = 'a@example.com';
INSERT INTO users_gen_my (email) VALUES ('a@example.com');
SELECT id, email, (deleted_at IS NOT NULL) AS deleted FROM users_gen_my;
