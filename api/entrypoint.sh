#!/bin/bash

set -e

# wait for postgres to be fully up
./wait-for-it.sh --host=postgres --port=5432 --strict -- echo "postgres fully loaded"

# run migrations on database
alembic upgrade head

# exec the CMD
exec "$@"
