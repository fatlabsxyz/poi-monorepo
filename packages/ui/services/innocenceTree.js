import { MerkleTree, PartialMerkleTree } from 'fixed-merkle-tree'

import { trees } from '@/constants'
import { download } from '@/store/snark'
import networkConfig from '@/networkConfig'
import { mimc, innocenceService } from '@/services'

// const supportedCaches = ['1', '56', '100', '137']

class MerkleTreeService {
  constructor({ netId, amount, currency, commitment, instanceName }) {
    this.netId = netId
    this.amount = amount
    this.currency = currency
    this.commitment = commitment
    this.instanceName = instanceName

    this.idb = window.$nuxt.$indexedDB(netId)
    // eslint-disable-next-line
    this.innocenceService = new innocenceService({
      netId,
      amount,
      currency,
      commitment,
      instanceName
    })
  }

  createTree({ events }) {
    const { merkleTreeHeight, emptyElement } = networkConfig[`netId${this.netId}`]

    return new MerkleTree(merkleTreeHeight, events, {
      zeroElement: emptyElement,
      hashFunction: mimc.hash
    })
  }

  async downloadEdge(name) {
    const slicedEdge = await download({
      name,
      eventName: 'trees',
      contentType: 'string'
    })

    if (!slicedEdge) {
      throw new Error('Cant download file')
    }

    return JSON.parse(slicedEdge)
  }

  createPartialTree({ elements }) {
    console.info('innocenceTree.js:createPartialTree', elements)
    const { emptyElement } = networkConfig[`netId${this.netId}`]

    return new MerkleTree(trees.LEVELS, elements, {
      zeroElement: emptyElement,
      hashFunction: mimc.hash
    })
  }

  async getTreeFromCache() {
    console.info('innocenceTree.js:getTreeFromCache')
    try {
      const innocentCommitments = await this.innocenceService.getInnocentCommitments()

      const partialTree = this.createPartialTree({
        edge: [],
        elements: innocentCommitments.map((com) => com.commitment)
      })
      return partialTree
    } catch (err) {
      return undefined
    }
  }

  async getTreeFromDB() {
    try {
      const stringifyCachedTree = await this.idb.getAll({
        storeName: `stringify_inno_tree_${this.instanceName}`
      })

      if (!stringifyCachedTree || !stringifyCachedTree.length) {
        return undefined
      }

      const [{ tree }] = stringifyCachedTree
      const parsedTree = JSON.parse(tree)
      const isPartial = '_edgeLeaf' in parsedTree

      const savedTree = isPartial
        ? PartialMerkleTree.deserialize(parsedTree, mimc.hash)
        : MerkleTree.deserialize(parsedTree, mimc.hash)

      if (isPartial) {
        const edgeIndex = savedTree.edgeIndex
        const indexOfEvent = savedTree.indexOf(this.commitment)

        // ToDo save edges mapping { edgeIndex, edgeSlice }
        if (indexOfEvent === -1 && edgeIndex !== 0) {
          const isCacheHasCommitment = await this.bloomService.checkBloom()

          if (isCacheHasCommitment) {
            let edge
            let elements = []

            for (let i = trees.PARTS_COUNT; i > 0; i--) {
              const slicedEdge = await this.downloadEdge(this.getFileName(i))

              if (edgeIndex > slicedEdge.edge.edgeIndex) {
                edge = slicedEdge.edge
                elements = [].concat(slicedEdge.elements, elements)
              }

              if (slicedEdge.elements.includes(this.commitment)) {
                break
              }
            }

            savedTree.shiftEdge(edge, elements)
          }
        }
      }

      return savedTree
    } catch (err) {
      return undefined
    }
  }

  async getTree() {
    console.info('innocenceTree.js:getTree')
    // const hasCache = supportedCaches.includes(this.netId.toString())

    // let cachedTree = await this.getTreeFromDB()
    // if (!cachedTree && hasCache) {
    // FIXME: maybe cache it to db...
    const cachedTree = await this.getTreeFromCache()
    // }
    return cachedTree
  }

  async saveTree({ tree }) {
    try {
      await this.idb.putItem({
        storeName: `stringify_inno_tree_${this.instanceName}`,
        data: {
          hashTree: '1', // need for replace tree
          tree: tree.toString()
        },
        key: 'hashTree'
      })
    } catch (err) {
      console.error('saveCachedTree has error:', err.message)
    }
  }
}

const TreesFactory = {
  instances: new Map(),

  getService(payload) {
    console.info('innocenceTree.js:getService', payload)
    const instanceName = `${payload.currency}_${payload.amount}`
    if (this.instances.has(instanceName)) {
      console.log('already have tree')
      return this.instances.get(instanceName)
    }

    console.log('merkle tree payload', payload)
    const instance = new MerkleTreeService(payload)
    this.instances.set(instanceName, instance)
    return instance
  }
}

export const innocenceTreesInterface = TreesFactory
