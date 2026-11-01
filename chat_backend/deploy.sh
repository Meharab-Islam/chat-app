#!/usr/bin/env bash
set -e

echo "=========================================="
echo "  Deploying / Updating Chat Backend API   "
echo "=========================================="

# 1. Pull latest git changes
git pull origin main || true

# 2. Rebuild and launch containers in background
docker compose build
docker compose up -d

# 3. Synchronize database schema inside running container
echo "Running database schema push..."
docker compose exec -T app npx prisma db push

echo "=========================================="
echo " Deployment Complete! Health Check:       "
echo " http://localhost:5000/api/health         "
echo "=========================================="

