import { Wallet } from 'ethers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import {
  EntryPoint,
  SimpleAccount,
  VerifyingPaymaster,
  VerifyingPaymaster__factory
} from '../typechain'
import {
  AddressZero,
  createAccount,
  createAccountOwner, createAddress, decodeRevertReason,
  deployEntryPoint, packPaymasterData, parseValidationData
} from './testutils'
import { DefaultsForUserOp, fillAndSign, fillSignAndPack, packUserOp, simulateValidation } from './UserOp'
import { arrayify, defaultAbiCoder, hexConcat, parseEther } from 'ethers/lib/utils'
import { PackedUserOperation } from './UserOperation'

const MOCK_VALID_UNTIL = '0x00000000deadbeef'
const MOCK_VALID_AFTER = '0x0000000000001234'
const MOCK_SIG = '0x1234'

describe('EntryPoint with VerifyingPaymaster', function () {
  let entryPoint: EntryPoint
  let accountOwner: Wallet
  const ethersSigner = ethers.provider.getSigner()
  let account: SimpleAccount
  let offchainSigner: Wallet

  let paymaster: VerifyingPaymaster
  before(async function () {
    this.timeout(20000)
    entryPoint = await deployEntryPoint()

    offchainSigner = createAccountOwner()
    accountOwner = createAccountOwner()

    paymaster = await new VerifyingPaymaster__factory(ethersSigner).deploy(entryPoint.address, offchainSigner.address)
    await paymaster.addStake(1, { value: parseEther('2') })
    await entryPoint.depositTo(paymaster.address, { value: parseEther('1') });
    ({ proxy: account } = await createAccount(ethersSigner, accountOwner.address, entryPoint.address))
  })

  describe('#parsePaymasterAndData', () => {
    it('should parse data properly', async () => {
      const paymasterAndData = packPaymasterData(
        paymaster.address,
        DefaultsForUserOp.paymasterVerificationGasLimit,
        DefaultsForUserOp.paymasterPostOpGasLimit,
        hexConcat([
          defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), MOCK_SIG
        ])
      )
      console.log(paymasterAndData)
      const res = await paymaster.parsePaymasterAndData(paymasterAndData)
      // console.log('MOCK_VALID_UNTIL, MOCK_VALID_AFTER', MOCK_VALID_UNTIL, MOCK_VALID_AFTER)
      // console.log('validUntil after', res.validUntil, res.validAfter)
      // console.log('MOCK SIG', MOCK_SIG)
      // console.log('sig', res.signature)
      expect(res.validUntil).to.be.equal(ethers.BigNumber.from(MOCK_VALID_UNTIL))
      expect(res.validAfter).to.be.equal(ethers.BigNumber.from(MOCK_VALID_AFTER))
      expect(res.signature).equal(MOCK_SIG)
    })
  })

  describe('#validatePaymasterUserOp', () => {
    it('should reject on no signature', async () => {
      const userOp = await fillSignAndPack({
        sender: account.address,
        paymaster: paymaster.address,
        paymasterData: hexConcat([defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), '0x1234'])
      }, accountOwner, entryPoint)
      expect(await simulateValidation(userOp, entryPoint.address)
        .catch(e => decodeRevertReason(e)))
        .to.include('invalid signature length in paymasterAndData')
    })

    it('should reject on invalid signature', async () => {
      const userOp = await fillSignAndPack({
        sender: account.address,
        paymaster: paymaster.address,
        paymasterData: hexConcat(
          [defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), '0x' + '00'.repeat(65)])
      }, accountOwner, entryPoint)
      expect(await simulateValidation(userOp, entryPoint.address)
        .catch(e => decodeRevertReason(e)))
        .to.include('ECDSAInvalidSignature')
    })

    describe('with wrong signature', () => {
      let wrongSigUserOp: PackedUserOperation
      const beneficiaryAddress = createAddress()
      before(async () => {
        const sig = await offchainSigner.signMessage(arrayify('0xdead'))
        wrongSigUserOp = await fillSignAndPack({
          sender: account.address,
          paymaster: paymaster.address,
          paymasterData: hexConcat([defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), sig])
        }, accountOwner, entryPoint)
      })

      it('should return signature error (no revert) on wrong signer signature', async () => {
        const ret = await simulateValidation(wrongSigUserOp, entryPoint.address)
        expect(parseValidationData(ret.returnInfo.paymasterValidationData).aggregator).to.match(/0x0*1$/)
      })

      it('handleOp revert on signature failure in handleOps', async () => {
        await expect(entryPoint.estimateGas.handleOps([wrongSigUserOp], beneficiaryAddress)).to.revertedWith('AA34 signature error')
      })
    })

    it('succeed with valid signature', async () => {
      const userOp1 = await fillAndSign({
        sender: account.address,
        paymaster: paymaster.address,
        paymasterData: hexConcat(
          [defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), '0x' + '00'.repeat(65)])
      }, accountOwner, entryPoint)
      const hash = await paymaster.getHash(packUserOp(userOp1), MOCK_VALID_UNTIL, MOCK_VALID_AFTER)
      const sig = await offchainSigner.signMessage(arrayify(hash))
      const userOp = await fillSignAndPack({
        ...userOp1,
        paymaster: paymaster.address,
        paymasterData: hexConcat([defaultAbiCoder.encode(['uint48', 'uint48'], [MOCK_VALID_UNTIL, MOCK_VALID_AFTER]), sig])
      }, accountOwner, entryPoint)
      const res = await simulateValidation(userOp, entryPoint.address)
      const validationData = parseValidationData(res.returnInfo.paymasterValidationData)
      expect(validationData).to.eql({
        aggregator: AddressZero,
        validAfter: parseInt(MOCK_VALID_AFTER),
        validUntil: parseInt(MOCK_VALID_UNTIL)
      })
    })
  })
})
