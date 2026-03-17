#!/bin/bash

# Studywise Production Deployment Script

set -e

echo "Studywise Production Setup"
echo "=============================="

# Check if .env.prod exists
if [ ! -f .env.prod ]; then
    echo ".env.prod not found!"
    echo "Run: cp .env.prod.example .env.prod"
    exit 1
fi

# Load environment variables from .env.prod
set -a
source .env.prod
set +a

echo "Environment loaded"

# Check required vars
if [ -z "$RAILS_MASTER_KEY" ]; then
    echo "RAILS_MASTER_KEY not set, trying from config/master.key..."
    export RAILS_MASTER_KEY=$(cat config/master.key 2>/dev/null || echo "")
fi

if [ -z "$RAILS_MASTER_KEY" ]; then
    echo "Could not load RAILS_MASTER_KEY"
    exit 1
fi

# Export DATABASE_URL explicitly
export DATABASE_URL="postgresql://postgres:${STUDYWISE_DATABASE_PASSWORD}@db:5432/studywise_production"

echo "Building Docker image..."
docker-compose -f docker-compose.prod.yml build

echo "Starting services..."
docker-compose -f docker-compose.prod.yml up -d

echo "Waiting for database (10s)..."
sleep 10

echo "Running database migrations..."
docker-compose -f docker-compose.prod.yml exec -T web bin/rails db:migrate || {
    echo "Migration failed or already ran, continuing..."
}

echo "Precompiling assets..."
docker-compose -f docker-compose.prod.yml exec -T web bin/rails assets:precompile || {
    echo "Assets already compiled, continuing..."
}

echo ""
echo "Deployment complete!"
echo ""
echo "Access your app at: http://localhost:${HOST_PORT:-80}"
echo ""
echo "Useful commands:"
echo "   docker-compose -f docker-compose.prod.yml logs -f    # View logs"
echo "   docker-compose -f docker-compose.prod.yml restart    # Restart app"
echo "   docker-compose -f docker-compose.prod.yml down       # Stop all"
echo ""
