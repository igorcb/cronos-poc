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
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')

echo "Checking connection to: $DB_HOST:$DB_PORT"

# Wait for database to be ready (max 60 seconds with pg_isready)
max_attempts=60
attempt=1

until PGPASSWORD=dummy psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d railway -c "SELECT 1" &> /dev/null || [ $attempt -eq $max_attempts ]; do
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

echo "========================================"
echo "Running database seed..."
echo "========================================"
bin/rails db:seed

echo "========================================"
echo "Starting Rails server..."
echo "========================================"
exec bin/rails server -b 0.0.0.0 -p 3000
