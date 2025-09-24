# Proof of Innocence Monorepo

Privacy-preserving compliance solution for Tornado Cash users to prove transaction innocence without revealing identity.

## Prerequisites

- Node.js >= 14.0.0
- Yarn >= 1.22.0
- Foundry (for smart contracts)

## Quick Start

```bash
# Install dependencies
yarn install

# Setup environment files
cp packages/contracts/.env.example packages/contracts/.env
cp packages/relayer/.env.example packages/relayer/.env
cp packages/ui/.env.example packages/ui/.env

# Configure each .env file with your values
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
```bash
# Contracts
yarn contracts:build
yarn contracts:test
yarn contracts:deploy:sepolia
yarn contracts:deploy:mainnet

# Relayer
yarn relayer:start    # Start all services
yarn relayer:server   # API server only
yarn relayer:worker   # Worker only

# UI (requires Node 14 - use nvm or node version manager if needed)
yarn ui:dev           # Development server
yarn ui:build         # Production build
yarn ui:start         # Production server
yarn ui:generate      # Static generation
```

## Deployment Flow

1. **Deploy Contracts**
   ```bash
   yarn contracts:deploy:sepolia
   # Note the deployed PROOF_REGISTRY_ADDRESS
   ```

2. **Configure Services**
   - Update PROOF_REGISTRY_ADDRESS in relayer and UI .env files

3. **Start Services**
   ```bash
   yarn relayer:start
   yarn ui:dev
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

## License

MIT