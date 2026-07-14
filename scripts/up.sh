#!/usr/bin/env bash
# 両DBを起動し、初期化（シード投入）完了までブロックする。
# 初回は orders 100万件の投入に数分かかる。
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> docker compose up -d"
docker compose up -d

echo "==> PostgreSQL 18 の準備完了を待機..."
until docker compose exec -T pg pg_isready -U app -d app >/dev/null 2>&1; do
  sleep 2
done
# シード投入（orders 100万）が終わるまで件数で確認
echo "==> orders 100万件の投入を待機（初回は数分）..."
until [ "$(docker compose exec -T pg psql -U app -d app -tAc \
  'SELECT count(*) FROM orders' 2>/dev/null || echo 0)" -ge 1000000 ]; do
  sleep 3
done
echo "    PostgreSQL: orders $(docker compose exec -T pg psql -U app -d app -tAc 'SELECT count(*) FROM orders') 件 OK"

echo "==> MySQL 8.4 の準備完了を待機..."
until docker compose exec -T mysql mysqladmin ping -uroot -proot --silent >/dev/null 2>&1; do
  sleep 2
done
until [ "$(docker compose exec -T mysql mysql -uroot -proot -N -e \
  'SELECT count(*) FROM app.orders' 2>/dev/null || echo 0)" -ge 1000000 ]; do
  sleep 3
done
echo "    MySQL: orders $(docker compose exec -T mysql mysql -uroot -proot -N -e 'SELECT count(*) FROM app.orders') 件 OK"

echo ""
echo "準備完了。接続例:"
echo "  docker compose exec pg psql -U app -d app"
echo "  docker compose exec mysql mysql -uroot -proot app"
