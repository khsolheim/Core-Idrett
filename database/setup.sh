#!/bin/bash

# Database setup script for Core - Idrett
# Usage: ./setup.sh [database_name] [user] [password]

DB_NAME=${1:-core_idrett}
DB_USER=${2:-postgres}
DB_PASSWORD=${3:-postgres}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo "Setting up database: $DB_NAME"

# Create database if it doesn't exist
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME"

# Run migrations in order
for migration in migrations/*.sql; do
    echo "Running migration: $migration"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration"
done

echo "Database setup complete!"
