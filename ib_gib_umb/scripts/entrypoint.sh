#!/bin/bash

set -e

echo "1: $1"
host="$1"
echo "host: $host"
echo ""

echo "2: $2"
PORT="$2"
echo "PORT: $PORT"
echo ""

echo "3: $3"
PG_PORT="$3"
echo "PG_PORT: $PG_PORT"
echo ""

echo "4: $4"
POSTGRES_USER="$4"
echo "POSTGRES_USER: $POSTGRES_USER"
echo ""

echo "5: $5"
POSTGRES_PASSWORD="$5"
echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo ""

echo "6: $6"
app_bin="$6"
echo ""

echo "7: $7"
foreground="$7"
echo ""

cmd="$app_bin $foreground"
echo "cmd: $cmd"
echo ""

# echo "@ is"
# echo "$@"

export PGPASSWORD="$POSTGRES_PASSWORD"

until psql -h "$host" -U $POSTGRES_USER -c '\l'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 2
done

>&2 echo "cmd arg: ${cmd}"
>&2 echo "Postgres is up - entering app"
exec $cmd
