#!/bin/bash
cd /home/dev15/aniket/studywise

# Load environment
set -a
source .env.prod
set +a

# Get master key if not set
if [ -z "$RAILS_MASTER_KEY" ]; then
    export RAILS_MASTER_KEY=$(cat config/master.key)
fi

# Open Rails console (production env is already set in container)
docker-compose -f docker-compose.prod.yml exec web bin/rails console
