<template>
  <section class="section proof-registry">
    <div class="proof-table-wrapper">
      <h1 class="title is-4 has-text-centered mb-5">Proof Registry</h1>

      <b-field label="Search by Nullifier Hash" class="mb-4">
        <b-input v-model="searchNullifier" placeholder="Enter part of nullifier hash" expanded />
      </b-field>

      <b-table
        :data="paginatedProofs"
        :loading="loading"
        detailed
        detail-key="nullifierHash"
        class="is-fullwidth"
      >
        <b-table-column field="type" label="Type" width="10%">
          <template v-slot="props">
            {{ props.row.type }}
          </template>
        </b-table-column>

        <b-table-column field="sender" label="Sender" width="20%">
          <template v-slot="props">
            <span class="is-clickable has-text-link" @click="copyToClipboard(props.row.sender)">
              {{ truncateAddress(props.row.sender) }}
            </span>
          </template>
        </b-table-column>

        <b-table-column field="pool" label="Pool" width="20%">
          <template v-slot="props">
            <span class="is-clickable has-text-link" @click="copyToClipboard(props.row.pool)">
              {{ getPoolLabel(props.row.pool) }}
            </span>
          </template>
        </b-table-column>

        <b-table-column field="nullifierHash" label="Nullifier Hash">
          <template v-slot="props">
            <span class="is-clickable has-text-link" @click="copyToClipboard(props.row.nullifierHash)">
              {{ truncateHash(props.row.nullifierHash) }}
            </span>
          </template>
        </b-table-column>

        <b-table-column field="value" label="Root">
          <template v-slot="props">
            <span class="is-clickable has-text-link" @click="copyToClipboard(props.row.value)">
              {{ truncateRoot(props.row.value) }}
            </span>
          </template>
        </b-table-column>

        <b-table-column field="treeLink" label="Whitelist Tree">
          <template v-slot="props">
            <a
              v-if="props.row.treeLink"
              class="is-link"
              :href="props.row.treeLink"
              target="_blank"
              rel="noopener noreferrer"
            >
              View Tree
            </a>
          </template>
        </b-table-column>

        <b-table-column field="txHash" label="Tx">
          <template v-slot="props">
            <a
              class="is-link"
              :href="`https://etherscan.io/tx/${props.row.txHash}`"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ truncateHash(props.row.txHash) }}
            </a>
          </template>
        </b-table-column>
      </b-table>
      <b-pagination
        v-if="pageCount > 1"
        :total="filteredProofs.length"
        :current.sync="currentPage"
        :per-page="perPage"
        size="is-small"
        class="mt-4"
        rounded
      />
    </div>
  </section>
</template>

<script>
import { ethers } from 'ethers'

export default {
  data() {
    return {
      loading: true,
      proofs: [],
      filteredProofs: [],
      currentPage: 1,
      perPage: 50,
      searchNullifier: '',
      useMockData: true
    }
  },
  computed: {
    paginatedProofs() {
      const start = (this.currentPage - 1) * this.perPage
      return this.filteredProofs.slice(start, start + this.perPage)
    },
    pageCount() {
      return Math.ceil(this.filteredProofs.length / this.perPage)
    }
  },
  watch: {
    searchNullifier() {
      this.filterProofs()
    }
  },
  async mounted() {
    try {
      this.proofs = this.useMockData ? this.generateMockProofs() : await this.fetchProofsFromBlockchain()

      this.filteredProofs = this.proofs
    } catch (error) {
      console.error('Failed to load proofs:', error)
    } finally {
      this.loading = false
    }
  },
  methods: {
    truncateAddress(addr) {
      return addr.slice(0, 6) + '...' + addr.slice(-4)
    },
    truncateHash(hash) {
      return hash.slice(0, 6) + '...' + hash.slice(-4)
    },
    truncateRoot(hash) {
      return hash.slice(0, 4) + '...' + hash.slice(-4)
    },
    copyToClipboard(text) {
      navigator.clipboard.writeText(text)
      this.$buefy.toast.open({
        message: `Copied to clipboard: ${text}`,
        type: 'is-success'
      })
    },
    getPoolLabel(address) {
      const POOLS = {
        '0x12D66f87A04A9E220743712cE6d9bB1B5616B8Fc': '0.1 ETH',
        '0x47CE0C6eD5B0Ce3d3A51fdb1C52DC66a7c3c2936': '1 ETH',
        '0x910Cbd523D972eb0a6f4cAe4618aD62622b39DbF': '10 ETH',
        '0xA160cdAB225685dA1d56aa342Ad8841c3b53f291': '100 ETH'
      }
      return POOLS[address] || 'Unknown Pool'
    },
    filterProofs() {
      const query = this.searchNullifier.toLowerCase().trim()
      this.filteredProofs = this.proofs.filter((p) => p.nullifierHash.toLowerCase().includes(query))
      this.currentPage = 1
    },
    generateMockProofs() {
      const randHex = () =>
        '0x' + [...Array(64)].map(() => Math.floor(Math.random() * 16).toString(16)).join('')
      const proofs = []

      for (let i = 0; i < 100; i++) {
        const isMembership = i < 50
        const timestamp = Date.now() - i * 1000 * 60 // 1-minute interval spacing

        proofs.push({
          type: isMembership ? 'Membership' : 'Withdrawn',
          sender: randHex().slice(0, 42),
          pool: randHex().slice(0, 42),
          nullifierHash: randHex(),
          value: isMembership ? (Math.random() * 0.01).toFixed(6) : randHex(),
          txHash: randHex(),
          treeLink: `https://0xbow.io/poi/tree/${randHex()}`,
          timestamp
        })
      }

      return proofs.sort((a, b) => b.timestamp - a.timestamp)
    },
    async fetchProofsFromBlockchain() {
      const PROOF_REGISTRY_ADDRESS = process.env.PROOF_REGISTRY_ADDRESS
      const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL)
      // const provider = new ethers.providers.JsonRpcProvider(
      //   'https://virtual.mainnet.rpc.tenderly.co/4584cfa3-1295-4846-a580-617ea6dfea7a'
      // )

      const ABI = [
        'event MembershipProofSubmitted(address indexed sender, address indexed pool, bytes32 indexed nullifierHash, uint256 fee)',
        'event WithdrawnAndProved(address indexed sender, address indexed pool, bytes32 indexed nullifierHash, uint256 membershipRoot)'
      ]

      const contract = new ethers.Contract(PROOF_REGISTRY_ADDRESS, ABI, provider)

      const membershipLogs = await contract.queryFilter(
        contract.filters.MembershipProofSubmitted(),
        0,
        'latest'
      )

      const withdrawnLogs = await contract.queryFilter(contract.filters.WithdrawnAndProved(), 0, 'latest')

      return [
        ...membershipLogs.map((log) => ({
          type: 'Membership',
          sender: log.args.sender,
          pool: log.args.pool,
          nullifierHash: log.args.nullifierHash,
          value: ethers.utils.formatEther(log.args.fee),
          txHash: log.transactionHash,
          treeLink: `https://0xbow.io/poi/tree/${log.args.membershipRoot?.toString() || 'unknown'}`
        })),
        ...withdrawnLogs.map((log) => ({
          type: 'Withdrawn',
          sender: log.args.sender,
          pool: log.args.pool,
          nullifierHash: log.args.nullifierHash,
          value: log.args.membershipRoot.toString(),
          txHash: log.transactionHash,
          treeLink: `https://0xbow.io/poi/tree/${log.args.membershipRoot.toString()}`
        }))
      ]
    }
  }
}
</script>

<style scoped>
.proof-table-wrapper {
  max-width: 100%;
  padding: 0 1rem;
}

@media (min-width: 1024px) {
  .proof-table-wrapper {
    max-width: 1200px;
    margin: 0 auto;
  }
}

.b-table .table {
  table-layout: fixed;
  word-wrap: break-word;
  background-color: #121212; /* dark background */
  color: #e0e0e0; /* light text */
}

.b-table th {
  background-color: #1e1e1e;
  color: #ffffff;
}

.b-table td {
  background-color: #121212;
  color: #e0e0e0;
  text-align: center;
  vertical-align: middle;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.b-table a {
  color: #4fc1ff; /* etherscan link - nice blue */
}

.b-table a:hover {
  text-decoration: underline;
}

.is-clickable {
  cursor: pointer;
}
</style>
