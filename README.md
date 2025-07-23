# Proof of Innocence Monorepo

Privacy-preserving compliance solution for Tornado Cash users to prove transaction innocence without revealing identity.

## Prerequisites

- Node.js >= 18.0.0
- Yarn >= 1.22.0
- Foundry (for smart contracts)
- Docker (for relayer)

## Quick Start

```bash
# Clone and setup
git clone git@github.com:fatlabsxyz/poi-monorepo.git
cd proof-of-innocence-monorepo

# Install dependencies
yarn install

# Setup environment files
cp packages/contracts/.env.example packages/contracts/.env
cp packages/relayer/.env.example packages/relayer/.env
cp packages/ui/.env.example packages/ui/.env

# Configure each .env file with your values
```

## Project Structure

```
proof-of-innocence-monorepo/
├── packages/
│   ├── contracts/     # Smart contracts (Foundry)
│   ├── relayer/       # Backend relayer service (Node.js)
│   └── ui/            # Frontend interface (Nuxt.js)
├── pnpm-workspace.yaml
└── package.json
```

## Development

### All Packages
```bash
yarn dev              # Run all packages in dev mode
yarn build            # Build all packages
yarn test             # Test all packages
yarn lint             # Lint all packages
```

### Individual Packages

#### Contracts
```bash
cd packages/contracts

# Build
pnpm build
pnpm build:optimized

# Test
pnpm test
pnpm test:unit
pnpm test:integration

# Deploy
pnpm deploy:mainnet
pnpm deploy:sepolia
```

#### Relayer
```bash
cd packages/relayer

# Development
pnpm start            # Start all services
pnpm server           # API server only
pnpm worker           # Worker only

# With Docker
docker-compose up -d
```

#### UI
```bash
cd packages/ui

# Use Node 14 for UI
nvm use 14

# Development
yarn dev

# Production
yarn build
yarn generate         # Static generation
yarn start           # Production server
```

## Environment Configuration

### Contracts (.env)
```bash
MAINNET_RPC=          # Ethereum mainnet RPC
MAINNET_DEPLOYER_NAME= # Deployer account name
SEPOLIA_RPC=          # Sepolia testnet RPC
SEPOLIA_DEPLOYER_NAME= # Sepolia deployer name
ETHERSCAN_API_KEY=    # For contract verification
```

### Relayer (.env)
```bash
NET_ID=1              # Network ID
HTTP_RPC_URL=         # HTTP RPC endpoint
WS_RPC_URL=           # WebSocket RPC endpoint
PRIVATE_KEY=          # Relayer private key
PROOF_REGISTRY_ADDRESS= # Deployed contract address
REDIS_URL=redis://127.0.0.1:6379
```

### UI (.env)
```bash
PROOF_REGISTRY_ADDRESS= # Deployed contract address
RPC_URL=              # Default RPC endpoint
INFURA_KEY=           # Infura project ID
```

## Deployment Flow

1. **Deploy Contracts**
   ```bash
   cd packages/contracts
   pnpm deploy:sepolia
   # Note the deployed PROOF_REGISTRY_ADDRESS
   ```

2. **Configure Relayer**
   - Update PROOF_REGISTRY_ADDRESS in relayer .env
   - Start relayer services

3. **Configure UI**
   - Update PROOF_REGISTRY_ADDRESS in UI .env
   - Build and deploy UI

## Common Issues

### SSH Passphrase Prompt
If you get SSH prompts during `pnpm install`, it's due to git dependencies. The package.json files have been updated to use HTTPS URLs instead.

### Port Conflicts
- Relayer API: 8000
- UI Dev Server: 3000
- Redis: 6379

### Build Failures
- Ensure Foundry is installed for contracts
- Check Node.js version (>= 18)
- Clear node_modules and reinstall

## Scripts Reference

### Root Level
- `yarn install` - Install all dependencies
- `yarn build` - Build all packages
- `yarn dev` - Run all in development
- `yarn contracts:deploy` - Deploy contracts
- `yarn relayer:start` - Start relayer
- `yarn ui:dev` - Start UI dev server

### Note on Node Versions
- UI requires Node 14 (use `nvm use 14`)
- Other packages work with Node 18+

## Architecture

The system consists of three main components:

1. **Smart Contracts**: ProofRegistry contract that verifies SNARK proofs
2. **Relayer**: Processes withdrawals and maintains merkle trees
3. **UI**: Web interface for users to generate and submit proofs

## License

MIT
