#!/usr/bin/env bash
# MySQL 8.4 に接続、または引数のSQLファイル/文を実行する。
#   scripts/mysql.sh                   # 対話 mysql
#   scripts/mysql.sh ch01/anti.sql     # ファイルを実行
#   scripts/mysql.sh -e "SELECT 1"     # 単文を実行
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -eq 0 ]; then
  exec docker compose exec mysql mysql -uroot -proot app
elif [ -f "${1:-}" ]; then
  exec docker compose exec -T mysql mysql -uroot -proot app < "$1"
else
  exec docker compose exec -T mysql mysql -uroot -proot app "$@"
fi
