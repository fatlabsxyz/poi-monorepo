<img src="https://raw.githubusercontent.com/defi-wonderland/brand/v1.0.0/external/solidity-foundry-boilerplate-banner.png" alt="wonderland banner" align="center" />
<br />

<div align="center"><strong>Start your next Solidity project with Foundry in seconds</strong></div>
<div align="center">A highly scalable foundation focused on DX and best practices</div>

<br />

## Features

<dl>
  <dt>Sample contracts</dt>
  <dd>Basic Greeter contract with an external interface.</dd>

  <dt>Foundry setup</dt>
  <dd>Foundry configuration with multiple custom profiles and remappings.</dd>

  <dt>Deployment scripts</dt>
  <dd>Sample scripts to deploy contracts on both mainnet and testnet.</dd>

  <dt>Sample Integration, Unit, Property-based fuzzed and symbolic tests</dt>
  <dd>Example tests showcasing mocking, assertions and configuration for mainnet forking. As well it includes everything needed in order to check code coverage.</dd>
  <dd>Unit tests are built based on the <a href="https://twitter.com/PaulRBerg/status/1682346315806539776">Branched-Tree Technique</a>, using <a href="https://github.com/alexfertel/bulloak">Bulloak</a>.
  <dd>Formal verification and property-based fuzzing are achieved with <a href="https://github.com/a16z/halmos">Halmos</a> and <a href="https://github.com/crytic/medusa">Medusa</a> (resp.).

  <dt>Linter</dt>
  <dd>Simple and fast solidity linting thanks to forge fmt.</dd>
  <dd>Find missing natspec automatically.</dd>

  <dt>Github workflows CI</dt>
  <dd>Run all tests and see the coverage as you push your changes.</dd>
  <dd>Export your Solidity interfaces and contracts as packages, and publish them to NPM.</dd>
</dl>

## Setup

1. Install Foundry by following the instructions from [their repository](https://github.com/foundry-rs/foundry#installation).
2. Copy the `.env.example` file to `.env` and fill in the variables.
3. Install the dependencies by running: `yarn install`. In case there is an error with the commands, run `foundryup` and try them again.
4. Install Foundry dependencies: 
   ```bash
   cd packages/contracts
   forge install
   ```

## Build

The default way to build the code is suboptimal but fast, you can run it via:

```bash
yarn build
```

In order to build a more optimized code ([via IR](https://docs.soliditylang.org/en/v0.8.15/ir-breaking-changes.html#solidity-ir-based-codegen-changes)), run:

```bash
yarn build:optimized
```

## Running tests

Unit tests should be isolated from any externalities, while Integration usually run in a fork of the blockchain. In this boilerplate you will find example of both.

In order to run both unit and integration tests, run:

```bash
yarn test
```

In order to just run unit tests, run:

```bash
yarn test:unit
```

In order to run unit tests and run way more fuzzing than usual (5x), run:

```bash
yarn test:unit:deep
```

In order to just run integration tests, run:

```bash
yarn test:integration
```

In order to start the Medusa fuzzing campaign (requires [Medusa](https://github.com/crytic/medusa/blob/master/docs/src/getting_started/installation.md) installed), run:

```bash
yarn test:fuzz
```

In order to just run the symbolic execution tests (requires [Halmos](https://github.com/a16z/halmos/blob/main/README.md#installation) installed), run:

```bash
yarn test:symbolic
```

In order to check your current code coverage, run:

```bash
yarn coverage
```

<br>

## Deploy & verify

### Setup

1. Configure the `.env` file with your settings:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

2. Source the environment variables:
   ```bash
   source .env
   ```

### Deploy ProofRegistry Contract

1. **Deploy the contract:**
   ```bash
   forge create src/contracts/ProofRegistry.sol:ProofRegistry \
     --private-key $PRIVATE_KEY \
     --rpc-url $MAINNET_RPC \
     --etherscan-api-key $ETHERSCAN_API_KEY \
     --verifier-url $MAINNET_RPC/verify/etherscan \
     --verify \
     --broadcast
   ```

   Save the deployed contract address from the output.

2. **Initialize the contract:**
   ```bash
   cast send <DEPLOYED_ADDRESS> "initialize()" \
     --rpc-url $MAINNET_RPC \
     --private-key $PRIVATE_KEY
   ```

3. **Set the postman address:**
   ```bash
   cast send <DEPLOYED_ADDRESS> "setPostman(address)" <POSTMAN_ADDRESS> \
     --rpc-url $MAINNET_RPC \
     --private-key $PRIVATE_KEY
   ```

4. **Update the root hash:**
   ```bash
   cast send <DEPLOYED_ADDRESS> "updateRoot(bytes32)" 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef \
     --rpc-url $MAINNET_RPC \
     --private-key $PRIVATE_KEY
   ```

5. **Set the protocol fee (e.g., 0.1 ETH):**
   ```bash
   cast send <DEPLOYED_ADDRESS> "setProtocolFee(uint256)" 100000000000000000 \
     --rpc-url $MAINNET_RPC \
     --private-key $PRIVATE_KEY
   ```

### Environment Variables

Required environment variables in your `.env` file:
```bash
MAINNET_RPC=https://your-rpc-url
PRIVATE_KEY=your-private-key
DEPLOYER_ADDRESS=your-deployer-address
ETHERSCAN_API_KEY=your-etherscan-api-key  # Optional, for verification
```

### Complete Deployment Example

Here's a complete example using the deployer address as postman:

```bash
# Source environment
source .env

# Deploy
forge create src/contracts/ProofRegistry.sol:ProofRegistry \
  --private-key $PRIVATE_KEY \
  --rpc-url $MAINNET_RPC \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --verifier-url $MAINNET_RPC/verify/etherscan \
  --verify \
  --broadcast

# Save the deployed address from output, then:
DEPLOYED_ADDRESS=0x... # Replace with your deployed address

# Initialize
cast send $DEPLOYED_ADDRESS "initialize()" \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Set postman (using deployer as postman)
cast send $DEPLOYED_ADDRESS "setPostman(address)" $DEPLOYER_ADDRESS \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Update root
cast send $DEPLOYED_ADDRESS "updateRoot(bytes32)" 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Set fee (0.1 ETH)
cast send $DEPLOYED_ADDRESS "setProtocolFee(uint256)" 100000000000000000 \
  --rpc-url $MAINNET_RPC \
  --private-key $PRIVATE_KEY
```

### Post-Deployment Configuration

After deployment, update the following files with your contract address:
- UI: `packages/ui/.env` - Update `REACT_APP_PROOF_REGISTRY_ADDRESS`
- Relayer: `packages/relayer/.env` - Update `PROOF_REGISTRY_ADDRESS`

The deployments are stored in ./broadcast

See the [Foundry Book for available options](https://book.getfoundry.sh/reference/forge/forge-create.html).

## Export And Publish

Export TypeScript interfaces from Solidity contracts and interfaces providing compatibility with TypeChain. Publish the exported packages to NPM.

To enable this feature, make sure you've set the `NPM_TOKEN` on your org's secrets. Then set the job's conditional to `true`:

```yaml
jobs:
  export:
    name: Generate Interfaces And Contracts
    # Remove the following line if you wish to export your Solidity contracts and interfaces and publish them to NPM
    if: true
    ...
```

Also, remember to update the `package_name` param to your package name:

```yaml
- name: Export Solidity - ${{ matrix.export_type }}
  uses: defi-wonderland/solidity-exporter-action@1dbf5371c260add4a354e7a8d3467e5d3b9580b8
  with:
    # Update package_name with your package name
    package_name: "my-cool-project"
    ...


- name: Publish to NPM - ${{ matrix.export_type }}
  # Update `my-cool-project` with your package name
  run: cd export/my-cool-project-${{ matrix.export_type }} && npm publish --access public
  ...
```

You can take a look at our [solidity-exporter-action](https://github.com/defi-wonderland/solidity-exporter-action) repository for more information and usage examples.

## Licensing
The primary license for the boilerplate is MIT, see [`LICENSE`](https://github.com/defi-wonderland/solidity-foundry-boilerplate/blob/main/LICENSE)
