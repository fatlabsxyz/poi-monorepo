const express = require('express')
const { port, rewardAccount } = require('./config')
const { version } = require('../package.json')
const { isAddress } = require('./utils')
const router = require('./router')

if (!isAddress(rewardAccount)) {
  throw new Error('No REWARD_ACCOUNT specified')
}
const app = express()
app.use(express.json())
app.use(router)
app.listen(port, '0.0.0.0', () => {
  console.log(`Relayer ${version} started on 0.0.0.0:${port}`)
})
