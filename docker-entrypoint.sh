#!/bin/bash
set -e

echo "========================================"
echo "Waiting for database to be ready..."
echo "========================================"

# Wait for database to be ready (max 30 seconds)
max_attempts=30
attempt=1

until bin/rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" &> /dev/null || [ $attempt -eq $max_attempts ]; do
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
