#!/bin/bash
set -e

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
