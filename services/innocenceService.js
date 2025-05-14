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
        '0x26ee188888888888d9f6561f9f7e30d68a68e24ed90e09478e461b2cbc9d9acb',
        '0x16ee107c78de7edad9f6561f9f7e30d68a68e24ed888888888861b2cbc9d9acb',
        '0x16ee107c28de7edad9f6561f9f7e30d68a68e248888888478e461b2cbc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d688888888880e09478e461b2cbc9d9acb',
        '0x16ee107c98de7edad9f6561f988888888888e24ed90e09478e461b2cbc9d9acb',
        '0x16ee107c98de7edad9f65688888880d68a68e24ed90e09478e461b2cbc9d9acb',
        '0x16ee107c98de7edad888888f9f7e30d68a68e24ed90e09478e461b2cbc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cbc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cb8888acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2c888d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b888c9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b862c9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b853c9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b21bc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b29bc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b22bc9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2c7c9d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cbc1d9acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cbc939acb',
        '0x16ee107c98de7edad9f6561f9f7e30d68a68e24ed90e09478e461b2cbc2d9acb'
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
