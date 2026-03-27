#!/bin/bash

# Rebranding compatibility for STORAGE_DIR
if [ -z "$STORAGE_DIR" ] && [ ! -z "$AIAPPSY_LLM_STORAGE_DIR" ]; then
    export STORAGE_DIR="$AIAPPSY_LLM_STORAGE_DIR"
fi

# Check if STORAGE_DIR is set
if [ -z "$STORAGE_DIR" ]; then
    echo "================================================================"
    echo "⚠️  ⚠️  ⚠️  WARNING: STORAGE_DIR environment variable is not set! ⚠️  ⚠️  ⚠️"
    echo "Please set STORAGE_DIR=/app/server/storage for persistent data."
    echo "================================================================"
else
    echo "✅ STORAGE_DIR is set to $STORAGE_DIR"
fi

# Ensure storage directory exists and is writable
mkdir -p "$STORAGE_DIR"
if [ ! -w "$STORAGE_DIR" ]; then
    echo "❌ ERROR: STORAGE_DIR ($STORAGE_DIR) is not writable! Check volume permissions."
    exit 1
fi

echo "🚀 Starting AiAppsy LLM services..."

cd /app/server/
echo "🛠️ Generating Prisma client..."
export CHECKPOINT_DISABLE=1
npx prisma generate --schema=./prisma/schema.prisma || { echo "❌ Prisma generate failed!"; exit 1; }

echo "📦 Running database migrations..."
npx prisma migrate deploy --schema=./prisma/schema.prisma || { echo "❌ Prisma migrate failed!"; exit 1; }

echo "🌱 Seeding database..."
npx prisma db seed --schema=./prisma/schema.prisma || { echo "❌ Prisma seed failed!"; exit 1; }

echo "✅ Database is ready."

# Start both services and log their output
echo "🛰️ Starting Backend and Collector..."
echo "Starting AiAppsy LLM Server..."
node /app/server/index.js &
echo "Starting AiAppsy LLM Collector..."
node /app/collector/index.js &

echo "AiAppsy LLM services started. Waiting for processes..."
# Wait for any process to exit
wait -n

# Exit with status of the one that failed
exit $?