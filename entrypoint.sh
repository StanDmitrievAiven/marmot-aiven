#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Marmot...${NC}"
echo "DEBUG: Entrypoint script executed"
echo "DEBUG: DATABASE_URL=${DATABASE_URL:-NOT SET}"
echo "DEBUG: MARMOT_DATABASE_HOST=${MARMOT_DATABASE_HOST:-NOT SET}"
echo "DEBUG: All env vars with DATABASE:"
env | grep -i database || echo "  No DATABASE-related env vars found"

# Parse DATABASE_URL if provided (Aiven App Runtime format)
if [ -n "$DATABASE_URL" ]; then
    echo -e "${GREEN}Parsing DATABASE_URL from Aiven...${NC}"
    
    # Remove postgres:// prefix
    DB_URL="${DATABASE_URL#postgres://}"
    
    # Extract user:password@host:port/database?params
    USER_PASS="${DB_URL%%@*}"
    HOST_PORT_DB="${DB_URL#*@}"
    
    # Extract user and password
    export MARMOT_DATABASE_USER="${USER_PASS%%:*}"
    export MARMOT_DATABASE_PASSWORD="${USER_PASS#*:}"
    
    # Extract host:port and database?params
    HOST_PORT="${HOST_PORT_DB%%/*}"
    DB_PARAMS="${HOST_PORT_DB#*/}"
    
    # Extract host and port
    export MARMOT_DATABASE_HOST="${HOST_PORT%%:*}"
    export MARMOT_DATABASE_PORT="${HOST_PORT##*:}"
    
    # Extract database name (before ?)
    export MARMOT_DATABASE_NAME="${DB_PARAMS%%\?*}"
    
    # Extract sslmode from query params if present
    if [[ "$DB_PARAMS" == *"sslmode="* ]]; then
        SSL_PARAM="${DB_PARAMS##*sslmode=}"
        export MARMOT_DATABASE_SSLMODE="${SSL_PARAM%%&*}"
    else
        export MARMOT_DATABASE_SSLMODE="${MARMOT_DATABASE_SSLMODE:-require}"
    fi
    
    echo -e "${GREEN}Database configuration from DATABASE_URL:${NC}"
    echo "  Host: ${MARMOT_DATABASE_HOST}"
    echo "  Port: ${MARMOT_DATABASE_PORT}"
    echo "  User: ${MARMOT_DATABASE_USER}"
    echo "  Database: ${MARMOT_DATABASE_NAME}"
    echo "  SSL Mode: ${MARMOT_DATABASE_SSLMODE}"
else
    # Use individual variables if DATABASE_URL not provided
    echo -e "${GREEN}Using individual MARMOT_DATABASE_* environment variables...${NC}"
    
    if [ -z "$MARMOT_DATABASE_HOST" ]; then
        echo -e "${RED}Error: Either DATABASE_URL or MARMOT_DATABASE_HOST must be set${NC}"
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
    # Aiven PostgreSQL requires SSL - default to 'require' if not set
    export MARMOT_DATABASE_SSLMODE="${MARMOT_DATABASE_SSLMODE:-require}"
    
    echo -e "${GREEN}Database configuration from individual variables:${NC}"
    echo "  Host: ${MARMOT_DATABASE_HOST}"
    echo "  Port: ${MARMOT_DATABASE_PORT}"
    echo "  User: ${MARMOT_DATABASE_USER}"
    echo "  Database: ${MARMOT_DATABASE_NAME}"
    echo "  SSL Mode: ${MARMOT_DATABASE_SSLMODE}"
    
    echo -e "${GREEN}Database configuration:${NC}"
    echo "  Host: ${MARMOT_DATABASE_HOST}"
    echo "  Port: ${MARMOT_DATABASE_PORT}"
    echo "  User: ${MARMOT_DATABASE_USER}"
    echo "  Database: ${MARMOT_DATABASE_NAME}"
    echo "  SSL Mode: ${MARMOT_DATABASE_SSLMODE}"
fi

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
echo "DEBUG: Final environment variables being passed to Marmot:"
echo "  MARMOT_DATABASE_HOST=${MARMOT_DATABASE_HOST:-NOT SET}"
echo "  MARMOT_DATABASE_PORT=${MARMOT_DATABASE_PORT:-NOT SET}"
echo "  MARMOT_DATABASE_USER=${MARMOT_DATABASE_USER:-NOT SET}"
echo "  MARMOT_DATABASE_NAME=${MARMOT_DATABASE_NAME:-NOT SET}"
echo "  MARMOT_DATABASE_SSLMODE=${MARMOT_DATABASE_SSLMODE:-NOT SET}"

# Execute Marmot with provided arguments or default to "run"
exec /usr/local/bin/marmot "$@"
