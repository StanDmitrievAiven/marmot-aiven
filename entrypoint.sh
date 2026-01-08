#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Marmot...${NC}"

# Validate required environment variables
if [ -z "$MARMOT_DATABASE_HOST" ]; then
    echo -e "${RED}Error: MARMOT_DATABASE_HOST must be set${NC}"
    exit 1
fi

if [ -z "$MARMOT_DATABASE_PASSWORD" ]; then
    echo -e "${RED}Error: MARMOT_DATABASE_PASSWORD must be set${NC}"
    exit 1
fi

# Set defaults for optional database parameters
export MARMOT_DATABASE_PORT="${MARMOT_DATABASE_PORT:-5432}"
export MARMOT_DATABASE_USER="${MARMOT_DATABASE_USER:-marmot}"
export MARMOT_DATABASE_NAME="${MARMOT_DATABASE_NAME:-marmot}"
export MARMOT_DATABASE_SSLMODE="${MARMOT_DATABASE_SSLMODE:-require}"

echo -e "${GREEN}Database configuration:${NC}"
echo "  Host: ${MARMOT_DATABASE_HOST}"
echo "  Port: ${MARMOT_DATABASE_PORT}"
echo "  User: ${MARMOT_DATABASE_USER}"
echo "  Database: ${MARMOT_DATABASE_NAME}"
echo "  SSL Mode: ${MARMOT_DATABASE_SSLMODE}"

# Set server defaults
export MARMOT_SERVER_PORT="${MARMOT_SERVER_PORT:-8080}"
export MARMOT_SERVER_HOST="${MARMOT_SERVER_HOST:-0.0.0.0}"

# Set logging defaults
export MARMOT_LOGGING_LEVEL="${MARMOT_LOGGING_LEVEL:-info}"
export MARMOT_LOGGING_FORMAT="${MARMOT_LOGGING_FORMAT:-json}"

# Encryption key (required for pipeline credentials)
if [ -z "$MARMOT_SERVER_ENCRYPTION_KEY" ]; then
    echo -e "${YELLOW}Warning: MARMOT_SERVER_ENCRYPTION_KEY is not set${NC}"
    echo -e "${YELLOW}Pipeline credentials will be stored unencrypted if allow_unencrypted is enabled${NC}"
    export MARMOT_SERVER_ALLOW_UNENCRYPTED="${MARMOT_SERVER_ALLOW_UNENCRYPTED:-false}"
else
    echo -e "${GREEN}Encryption key is configured${NC}"
fi

# Auth defaults
export MARMOT_AUTH_ANONYMOUS_ENABLED="${MARMOT_AUTH_ANONYMOUS_ENABLED:-false}"
export MARMOT_AUTH_ANONYMOUS_ROLE="${MARMOT_AUTH_ANONYMOUS_ROLE:-user}"

# Metrics defaults
export MARMOT_METRICS_ENABLED="${MARMOT_METRICS_ENABLED:-false}"

# OpenLineage defaults
export MARMOT_OPENLINEAGE_AUTH_ENABLED="${MARMOT_OPENLINEAGE_AUTH_ENABLED:-true}"

echo -e "${GREEN}Starting Marmot server on ${MARMOT_SERVER_HOST}:${MARMOT_SERVER_PORT}${NC}"

# Execute Marmot with provided arguments or default to "run"
exec /usr/local/bin/marmot "$@"
