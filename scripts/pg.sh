#!/usr/bin/env bash
# PostgreSQL 18 に接続、または引数のSQLファイル/文を実行する。
#   scripts/pg.sh                      # 対話 psql
#   scripts/pg.sh ch01/anti.sql        # ファイルを実行
#   scripts/pg.sh -c "SELECT 1"        # 単文を実行
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -eq 0 ]; then
  exec docker compose exec pg psql -U app -d app
elif [ -f "${1:-}" ]; then
  exec docker compose exec -T pg psql -U app -d app < "$1"
else
  exec docker compose exec -T pg psql -U app -d app "$@"
fi
