const MTMSAirdrop = artifacts.require('MTMSAirdrop')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

const buf2hex = x => '0x'+x.toString('hex')

contract('Contracts', (accounts) => {
  let contract

  before('setup', async () => {
    contract = await MTMSAirdrop.new('0xf805D2C75ce02feB2b765B5CBEeDB32cBc7A2258')
  })

  context('MerkleProof', () => {
    describe('merkle proofs', () => {
      
      it('should return true for valid merkle proof (SO#63509)', async () => {
        const leaves = ['0x246197cC21190A9E556b6d6D8e8D835e40C33A31 50', '0x696ef482355DAC634575ac515CC8aaF86C905e5D 75', '0xb8ce805b2F346Ead5FA5eA1d9756b10fF46642B8 50', '0x1e27c325ba246f581a6dcaa912a8e80163454c75 10'].map(v => keccak256(v))
        const tree = new MerkleTree(leaves, keccak256, { sort: true })
        const root = tree.getRoot()
        const hexroot = buf2hex(root)
        const leaf = keccak256('0x1e27c325ba246f581a6dcaa912a8e80163454c75 10')
        const hexleaf = buf2hex(leaf)
        const proof = tree.getProof(leaf)
        const hexproof = tree.getProof(leaf).map(x => buf2hex(x.data))

        //const init = await contract.seedNewAllocations(root, 100000)
        const verified = await contract.verifyClaim('0xb8ce805b2F346Ead5FA5eA1d9756b10fF46642B8', 1, 50, hexproof)
        assert.equal(verified, true)

        assert.equal(tree.verify(proof, leaf, root), true)
      })
    })
  })
})
