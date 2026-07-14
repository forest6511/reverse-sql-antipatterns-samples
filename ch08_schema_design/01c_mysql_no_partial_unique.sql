DROP TABLE IF EXISTS users_naive_my;
CREATE TABLE users_naive_my (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    deleted_at DATETIME NULL
);
-- MySQL には WHERE 付き部分UNIQUEインデックスがない
CREATE UNIQUE INDEX idx_active ON users_naive_my (email) WHERE deleted_at IS NULL;
