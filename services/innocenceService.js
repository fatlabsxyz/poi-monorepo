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
    console.info('innocenceService.js:getInnocentCommitments')
    // const commitments = await fetch(S3_URL).json()[this.currency].filter(deposit => deposit.LEGIT === true).map(dep => dep.commitment)
    try {
      // NOTE(for: casio): Connect tree data here
      const commitments = JSON.stringify([
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cbc9d9acb'
        // '10371506057323049074852082944123185784408553875919677565840442451350758726347'
        // '15109715122726901799250949352805937960415981882353843744366915755572107404120'
      ])
      // let commitments = await data.text()
      await Promise.resolve()
      return JSON.parse(commitments).map((com) => ({ commitment: com }))
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
