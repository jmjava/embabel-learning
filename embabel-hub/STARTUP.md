# Embabel Hub Startup Guide

## Prerequisites

- Docker installed and running
- `OPENAI_API_KEY` environment variable set (see configuration below)

## Configuration

The `starthub.sh` script automatically sources environment variables from a `.env` file if present.

### Option 1: Using a .env file (Recommended)

Create a `.env` file in either:

- `embabel-hub/.env` (preferred, most specific)
- `embabel-learning/.env` (parent directory, fallback)

Add your OpenAI API key:

```bash
OPENAI_API_KEY=your-api-key-here
```

The script will automatically load this file when run.

### Option 2: Export environment variable

```bash
export OPENAI_API_KEY=your-api-key-here
```

### Option 3: Pass inline

```bash
OPENAI_API_KEY=your-api-key-here ./embabel-hub/starthub.sh
```

## Starting the Hub

Simply run:

```bash
./embabel-hub/starthub.sh
```

The script will:

1. Load environment variables from `.env` if present
2. Stop and remove any existing container
3. Start a new embabel-hub container
4. Wait for the application to start (30-60 seconds)
5. Verify the web server is responding

## Services

Once started, the following services are available:

- **Guide API**: http://localhost:1337
- **Neo4j Browser**: http://localhost:27474
- **Neo4j Bolt**: bolt://localhost:27687
  - Username: `neo4j`
  - Password: See container documentation (default: `embabel123` for local dev)
- **Frontend**: http://localhost:8042

## Troubleshooting

If the web server doesn't start, check the logs:

```bash
docker logs embabel-hub
```

Common issues:

- **401 Unauthorized**: Invalid or expired `OPENAI_API_KEY`
- **Application startup timeout**: Check logs for initialization errors
