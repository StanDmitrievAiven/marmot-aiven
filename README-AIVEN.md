# Marmot on Aiven App Runtime

This repository contains a Docker-based deployment configuration for Marmot designed to run on Aiven's App Runtime platform.

## Overview

Marmot is an open-source data catalog that helps you discover, understand, and leverage your data with powerful search and lineage visualization tools. This project provides a containerized setup that:

* Uses the official Marmot binary from `ghcr.io/marmotdata/marmot:latest`
* Runs on a Debian-based image with shell support
* Automatically runs database migrations on startup (handled by Marmot itself)
* Configures the application for Aiven App Runtime deployment

## Prerequisites

* Aiven account with App Runtime access
* PostgreSQL database service in Aiven (for Marmot's metadata storage)
* Git repository access (this repo)

## Required Environment Variables

The following environment variables **must** be set in your Aiven App Runtime configuration:

### Database Connection (Required)

**Option 1: Use Aiven's automatic service connection (Recommended)**
* Connect your PostgreSQL service in the "Connect services" step
* Aiven will automatically set `DATABASE_URL` environment variable
* The entrypoint script will automatically parse `DATABASE_URL` and configure Marmot

**Option 2: Manual configuration with individual variables**
* `MARMOT_DATABASE_HOST` - PostgreSQL hostname (required if DATABASE_URL not set)
* `MARMOT_DATABASE_PORT` - PostgreSQL port (default: 5432)
* `MARMOT_DATABASE_USER` - PostgreSQL username (default: marmot)
* `MARMOT_DATABASE_PASSWORD` - PostgreSQL password (required if DATABASE_URL not set)
* `MARMOT_DATABASE_NAME` - Database name (default: marmot)
* `MARMOT_DATABASE_SSLMODE` - **REQUIRED for Aiven**: Set to `require` (default: require, but explicitly set it to avoid issues)

### Server Configuration (Optional)

* `MARMOT_SERVER_PORT` - Port for Marmot to listen on (default: 8080)
* `MARMOT_SERVER_HOST` - Host to bind to (default: 0.0.0.0)
* `MARMOT_SERVER_ROOT_URL` - Root URL for the application (for OAuth redirects)

### Security Configuration (Recommended)

* `MARMOT_SERVER_ENCRYPTION_KEY` - Encryption key for pipeline credentials
  * **Important**: Generate a secure key using: `docker run --rm ghcr.io/marmotdata/marmot:latest generate-encryption-key`
  * If not set, pipeline credentials will be stored unencrypted (not recommended)
* `MARMOT_SERVER_ALLOW_UNENCRYPTED` - Allow unencrypted storage (default: false)

### Authentication Configuration (Optional)

* `MARMOT_AUTH_ANONYMOUS_ENABLED` - Enable anonymous access (default: false)
* `MARMOT_AUTH_ANONYMOUS_ROLE` - Role for anonymous users (default: user)

For OAuth providers (Google, GitHub, GitLab, Okta, Auth0, Slack), see [Marmot Authentication Documentation](https://marmotdata.io/docs/Configure/authentication).

### Logging Configuration (Optional)

* `MARMOT_LOGGING_LEVEL` - Log level: trace, debug, info, warn, error, fatal, panic (default: info)
* `MARMOT_LOGGING_FORMAT` - Log format: json or console (default: json)

### Metrics Configuration (Optional)

* `MARMOT_METRICS_ENABLED` - Enable Prometheus metrics (default: false)
* `MARMOT_METRICS_PORT` - Metrics port (default: 9090)

### OpenLineage Configuration (Optional)

* `MARMOT_OPENLINEAGE_AUTH_ENABLED` - Enable authentication for OpenLineage endpoint (default: true)

## Deployment to Aiven App Runtime

1. **Create a PostgreSQL Service** in Aiven (if you don't have one)
   * This will store Marmot's metadata and catalog information
   * Note the connection details (host, port, username, password, database name)

2. **Create an App Runtime Application**
   * Source: Point to this GitHub repository
   * Branch: `main`
   * Dockerfile: `Dockerfile` (automatically detected by Aiven)
   * Note: This builds from source with frontend included, ensuring the web UI is properly embedded

3. **Generate and Set Encryption Key**
   * Run: `docker run --rm ghcr.io/marmotdata/marmot:latest generate-encryption-key`
   * Copy the generated key
   * In Aiven App Runtime, add environment variable: `MARMOT_SERVER_ENCRYPTION_KEY` = (paste the generated key)

4. **Configure Environment Variables** (if not using automatic service connection)
   * Optionally set individual database parameters if not using `DATABASE_URL`
   * Optionally configure authentication, logging, and other settings

5. **Configure Port**
   * Open port **8080** in your App Runtime configuration
   * Marmot's web UI will be accessible on this port

6. **Deploy**
   * Aiven will automatically build and deploy your application
   * Check the logs to verify successful startup and migration

## Accessing the UI

Once deployed, access the Marmot web UI at:

```
https://<your-app-hostname>:8080/
```

**Troubleshooting:**

If you see a "404 page not found" error:

1. **Check the health endpoint** to verify the app is running:
   ```
   https://<your-app-hostname>:8080/health
   ```
   This should return `{"status":"healthy"}` if the app is running correctly.

2. **Check application logs** in Aiven to see if there are any errors during startup.

3. **Verify the static files are embedded** - The Dockerfile builds the frontend and embeds it in the binary. Check build logs to ensure the frontend build stage completes successfully.

4. **Try accessing the Swagger UI** to verify API endpoints are working:
   ```
   https://<your-app-hostname>:8080/swagger/index.html
   ```

**Note:** By default, anonymous authentication is disabled. Configure OAuth authentication or enable anonymous access for development/testing.

## Default Login Credentials

Marmot creates a default admin user on first startup:

* **Username**: `admin`
* **Password**: `admin`
* **Note**: You will be required to change the password on first login

After logging in with these credentials, you should:
1. Change the admin password immediately
2. Configure OAuth authentication for production use (recommended)
3. Or enable anonymous access for development/testing by setting `MARMOT_AUTH_ANONYMOUS_ENABLED=true`

## Connecting Data Sources

Marmot uses the **Marmot CLI** to ingest metadata from data sources. Here's how to connect your PostgreSQL database:

### Step 1: Install the Marmot CLI

```bash
curl -fsSL get.marmotdata.io | sh
```

Or download from: https://github.com/marmotdata/marmot/releases

### Step 2: Get an API Key

**Option A: Via Web UI (Recommended)**
1. Log into your Marmot instance (running on Aiven)
2. Click on your **user profile icon** (top right)
3. Select **"Profile"** from the dropdown
4. Click on the **"API Keys"** tab
5. Click **"New Key"** button
6. Enter a name for your API key (e.g., "CLI Access")
7. Click **"Generate Key"**
8. **Copy the key immediately** - it's only shown once!

**Option B: Via API (if UI doesn't work)**
```bash
curl -X POST https://<your-hostname>:8080/api/v1/users/apikeys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-jwt-token>" \
  -d '{"name": "CLI Access"}'
```

To get your JWT token, log in via the UI and check your browser's localStorage for the `jwt` key, or use the login API endpoint.

### Step 3: Create a Pipeline Configuration

Create a `pipeline.yaml` file with your data source configuration:

```yaml
name: "test-postgres-pipeline"

runs:
  - test_postgres:
      source: "postgresql"
      host: "pg-19acf03c-stan-dmitriev-test.l.aivencloud.com"
      port: 19030
      user: "avnadmin"
      password: "${POSTGRES_PASSWORD}"  # Set via environment variable
      ssl_mode: "require"
      include_databases: true
      include_columns: true
      enable_metrics: true
      discover_foreign_keys: true
      exclude_system_schemas: true
      tags:
        - "postgres"
        - "aiven"
        - "test"
```

### Step 4: Set Your Password as an Environment Variable

```bash
export POSTGRES_PASSWORD="AVNS_nrj71y-QN2VxLiR0hUk"
```

### Step 5: Run the Ingestion

```bash
marmot ingest \
  --config pipeline.yaml \
  --host https://<your-aiven-app-hostname>:8080 \
  --api-key <your-api-key-from-step-2>
```

Replace:
- `<your-aiven-app-hostname>` with your Aiven App Runtime hostname
- `<your-api-key-from-step-2>` with the API key you created

### Supported Data Sources

Marmot supports many data sources including:
- **PostgreSQL** (as shown above)
- **MySQL**
- **BigQuery**
- **Snowflake**
- **S3** / **GCS** / **Azure Blob Storage**
- **Kafka**
- **MongoDB**
- **ClickHouse**
- **Airflow**
- **dbt**
- And more...

See the [Marmot Plugins Documentation](https://marmotdata.io/docs/Plugins) for full configuration options.

### Troubleshooting API Key Creation

If you can't create API keys via the UI:
1. **Check you're logged in** - API keys require authentication
2. **Check browser console** - Look for any JavaScript errors
3. **Try the API directly** - Use Option B above with your JWT token
4. **Check permissions** - Ensure your user account is active

## Project Structure

```
.
├── Dockerfile.avn         # Multi-stage build using official Marmot image (recommended)
├── Dockerfile.avn.build   # Alternative: Build from source
├── entrypoint.sh          # Startup script that validates config and starts the server
├── .gitattributes         # Git configuration for line endings
└── README-AIVEN.md        # This file
```

## Dockerfile Options

### Dockerfile.avn (Recommended)
Uses the official Marmot image (`ghcr.io/marmotdata/marmot:latest`) and extracts the binary. This is faster and uses the official release.

### Dockerfile.avn.build (Alternative)
Builds Marmot from source. Use this if you need to customize the build or if you encounter issues with the official image.

## How It Works

The Dockerfile uses a multi-stage build process:

1. **Frontend Build Stage**: Builds the Marmot web UI using Node.js and pnpm
2. **Go Build Stage**: Compiles the Go binary with the frontend embedded using `-tags=production`
3. **Runtime Stage**: Creates a minimal Debian-based image with:
   * The Marmot binary (with embedded frontend)
   * Shell support for running the entrypoint script
   * Entrypoint script for configuration validation and startup

### Runtime

The entrypoint script:
* Validates required environment variables
* Parses `DATABASE_URL` if provided by Aiven
* Sets defaults for optional configuration
* Starts the Marmot server (which automatically runs migrations)

## Customization

### Using a Different Marmot Image Version

To use a different Marmot image version, set the build argument:

```dockerfile
ARG MARMOT_IMAGE=ghcr.io/marmotdata/marmot:v0.5.1
```

### Generating Encryption Key

Generate a secure encryption key using Docker (recommended):

```bash
docker run --rm ghcr.io/marmotdata/marmot:latest generate-encryption-key
```

Or if you have Marmot installed locally:

```bash
marmot generate-encryption-key
```

This will output a base64-encoded 32-byte key. Copy the generated key and set it as an environment variable in Aiven App Runtime.

### Adding OAuth Authentication

To enable OAuth authentication, set these environment variables (example for Google):

```bash
MARMOT_AUTH_GOOGLE_ENABLED=true
MARMOT_AUTH_GOOGLE_CLIENT_ID=<your-client-id>
MARMOT_AUTH_GOOGLE_CLIENT_SECRET=<your-client-secret>
MARMOT_AUTH_GOOGLE_REDIRECT_URL=https://<your-app-hostname>:8080/auth/google/callback
```

See [Marmot Authentication Documentation](https://marmotdata.io/docs/Configure/authentication) for details on other providers.

## Troubleshooting

### Database Connection Issues

* Verify your PostgreSQL connection parameters are correct
* Ensure the database is accessible from App Runtime
* Check that the database user has necessary permissions
* Verify SSL mode matches your database configuration

### Migration Failures

* Check the application logs for specific migration errors
* Ensure the database is empty or compatible with Marmot's schema
* Verify database connection parameters are valid
* Marmot automatically runs migrations on startup - check logs for migration status

### Port Configuration

* Ensure port 8080 is opened in your App Runtime configuration
* Check that no other service is using the same port
* Verify firewall rules allow traffic on port 8080

### Encryption Key Issues

* If you see errors about missing encryption key, set `MARMOT_SERVER_ENCRYPTION_KEY`
* Generate a new key using: `docker run --rm ghcr.io/marmotdata/marmot:latest generate-encryption-key`
* Ensure the key is the same across all Marmot instances if running multiple replicas

## Security Considerations

⚠️ **Important**: 

1. **Encryption Key**: Always set `MARMOT_SERVER_ENCRYPTION_KEY` in production. Pipeline credentials are encrypted using this key.

2. **Authentication**: By default, anonymous authentication is disabled. Configure OAuth authentication for production use.

3. **Database Security**: Use SSL connections (`MARMOT_DATABASE_SSLMODE=require`) for production databases.

4. **Network Security**: Restrict network access to the application and database.

5. **Secrets Management**: Use Aiven's secret management features for sensitive environment variables.

## Resources

* [Marmot Documentation](https://marmotdata.io/docs/introduction)
* [Marmot GitHub](https://github.com/marmotdata/marmot)
* [Aiven App Runtime Documentation](https://docs.aiven.io/docs/products/appruntime)

## License

This deployment configuration is provided as-is. Please refer to Marmot's license (MIT) for the application itself.
