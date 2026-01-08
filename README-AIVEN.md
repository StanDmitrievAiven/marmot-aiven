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

* `MARMOT_DATABASE_HOST` - PostgreSQL hostname (required)
* `MARMOT_DATABASE_PORT` - PostgreSQL port (default: 5432)
* `MARMOT_DATABASE_USER` - PostgreSQL username (default: marmot)
* `MARMOT_DATABASE_PASSWORD` - PostgreSQL password (required)
* `MARMOT_DATABASE_NAME` - Database name (default: marmot)
* `MARMOT_DATABASE_SSLMODE` - SSL mode: disable, require, verify-ca, verify-full (default: require)

### Server Configuration (Optional)

* `MARMOT_SERVER_PORT` - Port for Marmot to listen on (default: 8080)
* `MARMOT_SERVER_HOST` - Host to bind to (default: 0.0.0.0)
* `MARMOT_SERVER_ROOT_URL` - Root URL for the application (for OAuth redirects)

### Security Configuration (Recommended)

* `MARMOT_SERVER_ENCRYPTION_KEY` - Encryption key for pipeline credentials
  * **Important**: Generate a secure key using: `marmot generate-key`
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
   * Dockerfile: `Dockerfile.avn` (uses official image) or `Dockerfile.avn.build` (builds from source)

3. **Configure Environment Variables**
   * Add the required database connection parameters
   * Set `MARMOT_SERVER_ENCRYPTION_KEY` (generate using `marmot generate-key`)
   * Optionally configure authentication, logging, and other settings

4. **Configure Port**
   * Open port **8080** in your App Runtime configuration
   * Marmot's web UI will be accessible on this port

5. **Deploy**
   * Aiven will automatically build and deploy your application
   * Check the logs to verify successful startup and migration

## Accessing the UI

Once deployed, access the Marmot web UI at:

```
https://<your-app-hostname>:8080/
```

**Note:** By default, anonymous authentication is disabled. Configure OAuth authentication or enable anonymous access for development/testing.

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

### Using Dockerfile.avn (Official Image)

1. **Build Stage 1**: Extracts the Marmot binary from the official `ghcr.io/marmotdata/marmot:latest` image
2. **Build Stage 2**: Creates a Debian-based image with:
   * The Marmot binary copied from stage 1
   * Shell support for running the entrypoint script
   * Entrypoint script for configuration validation and startup

### Using Dockerfile.avn.build (Build from Source)

1. **Build Stage 1**: Builds the Marmot binary from source using Go
2. **Build Stage 2**: Creates a Debian-based image with:
   * The Marmot binary from the build stage
   * Shell support for running the entrypoint script
   * Entrypoint script for configuration validation and startup

### Runtime (Both Dockerfiles)

The entrypoint script:
* Validates required environment variables
* Sets defaults for optional configuration
* Starts the Marmot server (which automatically runs migrations)

## Customization

### Using a Different Marmot Image Version

To use a different Marmot image version, set the build argument:

```dockerfile
ARG MARMOT_IMAGE=ghcr.io/marmotdata/marmot:v0.5.1
```

### Generating Encryption Key

Generate a secure encryption key:

```bash
docker run --rm ghcr.io/marmotdata/marmot:latest generate-key
```

Or if you have Marmot installed locally:

```bash
marmot generate-key
```

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
* Generate a new key using `marmot generate-key`
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
