class InnocenceService {
  constructor({ netId, amount, currency, commitment, instanceName }) {
    this.netId = netId
    this.amount = amount
    this.currency = currency
    this.commitment = commitment
    this.instanceName = instanceName

    this.idb = window.$nuxt.$indexedDB(netId)
  }

  async getInnocentCommitments() {
    try {
      // NOTE(for: casio): Connect tree data here
      const commitments = JSON.stringify([
        {
          blockNumber: 22238850,
          transactionHash: '0x14f65a2c4c049d72e4047e34a776d548251bbef492072b3b49d85adc84c9587c',
          commitment: '0x07142c87dc7ddea485c1b28f98c4984182e4b20adebb31c7dfc2c7b27c0e63f4',
          leafIndex: 34401,
          timestamp: 1744293030
        },
        {
          blockNumber: 22238851,
          transactionHash: '0xc18b80b81acdf31725a6bfbb52495e7d0f3e7db6ab356a7cee726abe73a8c882',
          commitment: '0x2c35822ae8d1289d8e8dfb7ac8a3c244c337bea86cb81fdd7b5fe8785f2cb5f2',
          leafIndex: 34402,
          timestamp: 1744293036
        },
        {
          blockNumber: 22238852,
          transactionHash: '0x41cf9909de1e545f4af522e00c06edd32ff0fb85287f130a780914534f387a07',
          commitment: '0x1cc82c7489012e099bc294cef90d43b9bb229e0349d75b9b7be9e1c2b10cf035',
          leafIndex: 34403,
          timestamp: 1744293041
        }
      ])
      // let commitments = await data.text()
      await Promise.resolve()
      return commitments
    } catch (err) {
      console.error('failed getting innocent commitment cache', err)
    }
  }

  async saveInnocentCommitments({ commitmentTree }) {
    await Promise.resolve()
    try {
      this.idb.putItem({
        storeName: `stringify_inno_${this.instanceName}_commitments`,
        data: { commitmentTree },
        key: 'commitment'
      })
    } catch (err) {
      console.error('saveInnocentCommitment has error:', err.message)
    }
  }

  async getInnocentCommitmentsFromDB() {
    const result = await this.idb.getAll({ storeName: `stringify_inno_${this.instanceName}_commitments` })
    return result
  }
}

export const innocenceService = InnocenceService
