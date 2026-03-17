#!/bin/bash
cd /home/dev15/aniket/studywise

# Load env
set -a
source .env.prod
set +a

# Get master key if not set
if [ -z "$RAILS_MASTER_KEY" ]; then
    export RAILS_MASTER_KEY=$(cat config/master.key)
fi

# Stop and start
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

echo "Waiting for app to start..."
sleep 10

# Check status
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "App should be running at: http://localhost:${HOST_PORT:-80}"
