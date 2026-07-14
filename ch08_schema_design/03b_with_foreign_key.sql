DROP TABLE IF EXISTS orders_fk, users_fk;
CREATE TABLE users_fk (id bigint PRIMARY KEY, name text);
CREATE TABLE orders_fk (id bigint PRIMARY KEY,
    user_id bigint REFERENCES users_fk(id), amount int);
INSERT INTO users_fk VALUES (1,'alice'),(2,'bob');
INSERT INTO orders_fk VALUES (10,1,500),(11,2,300);
DELETE FROM users_fk WHERE id = 2;
