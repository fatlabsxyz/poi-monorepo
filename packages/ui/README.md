# Proof of Innocence UI

Web interface for the Proof of Innocence (PoI) system built on Tornado Cash.

## Setup

1. Install dependencies:
   ```bash
   yarn install
   ```

2. Configure environment:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

## Required Environment Variables

```bash
# Contract address from deployment
PROOF_REGISTRY_ADDRESS=0x...

# RPC URL (your Tenderly fork or mainnet)
RPC_URL=https://...

# Optional: For IPFS features
PINATA_API_KEY=
PINATA_SECRET_API_KEY=

# Optional: Additional RPC providers
INFURA_KEY=
ALCHEMY_MAINNET_KEY=

# App configuration
STORE_NAME=tornado
APP_ENS_NAME=tornadocash.eth
```

## Development

```bash
# Start development server
yarn dev
```

The UI will be available at `http://localhost:3000`

## Production Build

```bash
# Build for production
yarn build

# Start production server
yarn start

# Generate static files
yarn generate
```

## Connect to Your Deployment

1. Update `.env` with your `PROOF_REGISTRY_ADDRESS` from the contracts deployment
2. Set `RPC_URL` to your Tenderly fork or mainnet RPC
3. Start the dev server with `yarn dev`
4. Connect MetaMask to the same network
5. Navigate to the Proof of Innocence page

## Features

- Generate and submit innocence proofs
- View proof registry status
- Connect with MetaMask or WalletConnect
- Support for multiple networks

## Relayer Integration

The UI connects to the relayer service for submitting proofs. Make sure the relayer is running and accessible before testing proof submissions.