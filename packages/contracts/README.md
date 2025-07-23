# ProofRegistry Contracts

Smart contracts for the Proof of Innocence (PoI) system.

## Setup

1. Install dependencies:
   ```bash
   yarn install
   cd packages/contracts
   forge install
   ```

2. Configure environment:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   source .env
   ```

## Deploy & Configure

### Deploy ProofRegistry

```bash
forge create src/contracts/ProofRegistry.sol:ProofRegistry \
  --private-key $PRIVATE_KEY \
  --rpc-url $MAINNET_RPC \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verifier-url $MAINNET_RPC/verify/etherscan \
  --verify \
  --broadcast
```

Save the deployed address from the output.

### Initialize Contract

```bash
# Replace with your deployed address
PROOF_REGISTRY_ADDRESS=0x...

# 1. Initialize
cast send $PROOF_REGISTRY_ADDRESS "initialize(address,uint256)" \
  $DEPLOYER_ADDRESS 77 \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# 2. Set postman
cast send $PROOF_REGISTRY_ADDRESS "updatePostman(address,bool)" \
  $DEPLOYER_ADDRESS true \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# 3. Set root
cast send $PROOF_REGISTRY_ADDRESS "updateRoot(uint256,bytes32)" \
  6873620323993782603944420351984586107457721017538294381362105471703919802312 \
  0x1000000000000000000000000000000000000000000000000000000000000000 \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# 4. Set fees (optional - if you want to change from 77)
cast send $PROOF_REGISTRY_ADDRESS "updateFees(uint256)" \
  77 \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY
```

## Post-Deployment

Update these files with your deployed contract address:
- UI: `packages/ui/.env` → `REACT_APP_PROOF_REGISTRY_ADDRESS`
- Relayer: `packages/relayer/.env` → `PROOF_REGISTRY_ADDRESS`

## Build Commands

```bash
# Build contracts
yarn build

# Run tests
yarn test

# Generate coverage
yarn coverage
```