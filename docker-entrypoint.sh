#!/bin/bash
set -e

echo "========================================"
echo "Waiting for database to be ready..."
echo "========================================"

# Debug: Show DATABASE_URL (masked password)
if [ -n "$DATABASE_URL" ]; then
  echo "DATABASE_URL is set: ${DATABASE_URL%%:*}://***:***@${DATABASE_URL##*@}"
else
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

# Extract database connection details from DATABASE_URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')

echo "Checking connection to: $DB_HOST:$DB_PORT (database: $DB_NAME, user: $DB_USER)"

# Wait for database to be ready (max 60 seconds)
max_attempts=60
attempt=1

until PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" &> /dev/null || [ $attempt -eq $max_attempts ]; do
  echo "Database not ready yet (attempt $attempt/$max_attempts)... waiting 1 second"
  sleep 1
  attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
  echo "ERROR: Database did not become ready in time!"
  exit 1
fi

echo "Database is ready!"

echo "========================================"
echo "Running database migrations..."
echo "========================================"
bin/rails db:migrate
bin/rails db:migrate:cache
bin/rails db:migrate:queue
bin/rails db:migrate:cable

echo "========================================"
echo "Running database seed..."
echo "========================================"
bin/rails db:seed

echo "========================================"
echo "Starting Rails server..."
echo "========================================"
exec bin/rails server -b 0.0.0.0 -p 3000
