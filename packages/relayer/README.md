# Proof of Innocence Relayer

Relayer service for processing Tornado Cash withdrawals with Proof of Innocence.

## Requirements

- **Node.js v20+** (use `nvm use 20` if you have nvm)
- Docker & Docker Compose (recommended) OR Redis

## Setup

1. **Set Node version:**
   ```bash
   nvm use 20
   # or ensure you have Node.js v20+ installed
   ```

2. **Install dependencies:**
   ```bash
   yarn install
   ```

3. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

## Required Environment Variables

```bash
# Network
NET_ID=1
HTTP_RPC_URL=https://your-rpc-url
WS_RPC_URL=wss://your-rpc-url
ORACLE_RPC_URL=https://mainnet.infura.io  # Always mainnet for prices

# Redis (use redis://redis:6379/0 for Docker)
REDIS_URL=redis://redis:6379/0

# Server
APP_PORT=8000
VIRTUAL_HOST=localhost
LETSENCRYPT_HOST=localhost

# Private key (without 0x prefix)
PRIVATE_KEY=your-private-key

# Contract address from deployment
PROOF_REGISTRY_ADDRESS=0x...

# Fees and rewards
REGULAR_TORNADO_WITHDRAW_FEE=0.05  # 0.05%
MINING_SERVICE_FEE=0.05
REWARD_ACCOUNT=your-reward-address

# Gas settings
MAX_GAS_PRICE=1000  # in GWEI
BASE_FEE_RESERVE_PERCENTAGE=25
CONFIRMATIONS=4
```

## Running the Relayer

### Option 1: Docker Compose (Recommended)

```bash
# Start all services including Redis
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Test the relayer
curl http://localhost:8000/status
```

### Option 2: Local Development

```bash
# Make sure Redis is running
redis-cli ping
# If not: sudo systemctl start redis-server

# Start all services
yarn start

# Or run services individually:
yarn server       # API server
yarn worker       # Job processor
yarn treeWatcher  # Merkle tree monitor
yarn priceWatcher # Price oracle
yarn healthWatcher # Health monitoring
```

## API Endpoints

- `GET /status` - Health check
- `POST /v1/tornadoWithdraw` - Standard withdrawal
- `POST /v1/tornadoInnocentWithdraw` - Withdrawal with innocence proof
- `GET /v1/jobs/:id` - Check job status

## Testing

```bash
# Health check
curl http://localhost:8000/status

# Should return something like:
# {
#   "rewardAccount": "0x...",
#   "instances": {...},
#   "netId": 1,
#   "tornadoServiceFee": 0.05,
#   ...
# }
```

## Stopping Services

```bash
# Docker
docker-compose down

# Local
# Stop each process with Ctrl+C
```

## Troubleshooting

- **Node version error**: Make sure you're using Node.js v20+ (`node --version`)
- **Redis connection error**: Ensure Redis is running (`redis-cli ping`)
- **RPC errors**: Verify your RPC endpoints are accessible
- **Contract not found**: Confirm PROOF_REGISTRY_ADDRESS matches your deployment

## Architecture

- **Server**: Express.js API that accepts HTTP requests
- **Worker**: Processes withdrawal jobs from the queue
- **TreeWatcher**: Monitors Account Tree changes
- **PriceWatcher**: Updates token prices from oracles
- **HealthWatcher**: Monitors service health
- **Redis**: Stores job queue and caches tree state