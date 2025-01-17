import { Wallet } from 'ethers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import {
  SimpleAccount,
  LegacyTokenPaymaster,
  LegacyTokenPaymaster__factory,
  TestCounter__factory,
  SimpleAccountFactory,
  SimpleAccountFactory__factory, EntryPoint
} from '../typechain'
import {
  AddressZero,
  createAccountOwner,
  fund,
  getBalance,
  getTokenBalance,
  rethrow,
  checkForGeth,
  calcGasUsage,
  deployEntryPoint,
  createAddress,
  ONE_ETH,
  createAccount,
  getAccountAddress, decodeRevertReason
} from './testutils'
import { fillSignAndPack, simulateValidation } from './UserOp'
import { hexConcat, parseEther } from 'ethers/lib/utils'
import { PackedUserOperation } from './UserOperation'
import { hexValue } from '@ethersproject/bytes'

describe('EntryPoint with paymaster', function () {
  let entryPoint: EntryPoint
  let accountOwner: Wallet
  const ethersSigner = ethers.provider.getSigner()
  let account: SimpleAccount
  const beneficiaryAddress = '0x'.padEnd(42, '1')
  let factory: SimpleAccountFactory

  function getAccountDeployer (entryPoint: string, accountOwner: string, _salt: number = 0): string {
    return hexConcat([
      factory.address,
      hexValue(factory.interface.encodeFunctionData('createAccount', [accountOwner, _salt])!)
    ])
  }

  before(async function () {
    this.timeout(20000)
    await checkForGeth()

    entryPoint = await deployEntryPoint()
    factory = await new SimpleAccountFactory__factory(ethersSigner).deploy(entryPoint.address)

    accountOwner = createAccountOwner();
    ({ proxy: account } = await createAccount(ethersSigner, await accountOwner.getAddress(), entryPoint.address, factory))
    await fund(account)
  })

  describe('#TokenPaymaster', () => {
    let paymaster: LegacyTokenPaymaster
    const otherAddr = createAddress()
    let ownerAddr: string
    let pmAddr: string

    before(async () => {
      paymaster = await new LegacyTokenPaymaster__factory(ethersSigner).deploy(factory.address, 'ttt', entryPoint.address)
      pmAddr = paymaster.address
      ownerAddr = await ethersSigner.getAddress()
    })

    it('paymaster should revert on wrong entryPoint type', async () => {
      // account is a sample contract with supportsInterface (which is obviously not an entrypoint)
      const notEntryPoint = account
      // a contract that has "supportsInterface" but with different interface value..
      await expect(new LegacyTokenPaymaster__factory(ethersSigner).deploy(factory.address, 'ttt', notEntryPoint.address))
        .to.be.revertedWith('IEntryPoint interface mismatch')
      await expect(new LegacyTokenPaymaster__factory(ethersSigner).deploy(factory.address, 'ttt', AddressZero))
        .to.be.revertedWith('')
    })

    it('owner should have allowance to withdraw funds', async () => {
      expect(await paymaster.allowance(pmAddr, ownerAddr)).to.equal(ethers.constants.MaxUint256)
      expect(await paymaster.allowance(pmAddr, otherAddr)).to.equal(0)
    })

    it('should allow only NEW owner to move funds after transferOwnership', async () => {
      await paymaster.transferOwnership(otherAddr)
      expect(await paymaster.allowance(pmAddr, otherAddr)).to.equal(ethers.constants.MaxUint256)
      expect(await paymaster.allowance(pmAddr, ownerAddr)).to.equal(0)
    })
  })

  describe('using TokenPaymaster (account pays in paymaster tokens)', () => {
    let paymaster: LegacyTokenPaymaster
    before(async () => {
      paymaster = await new LegacyTokenPaymaster__factory(ethersSigner).deploy(factory.address, 'tst', entryPoint.address)
      await entryPoint.depositTo(paymaster.address, { value: parseEther('1') })
      await paymaster.addStake(1, { value: parseEther('2') })
    })

    describe('#handleOps', () => {
      let calldata: string
      before(async () => {
        const updateEntryPoint = await account.populateTransaction.withdrawDepositTo(AddressZero, 0).then(tx => tx.data!)
        calldata = await account.populateTransaction.execute(account.address, 0, updateEntryPoint).then(tx => tx.data!)
      })
      it('paymaster should reject if account doesn\'t have tokens', async () => {
        const op = await fillSignAndPack({
          sender: account.address,
          paymaster: paymaster.address,
          paymasterPostOpGasLimit: 3e5,
          callData: calldata
        }, accountOwner, entryPoint)
        expect(await entryPoint.callStatic.handleOps([op], beneficiaryAddress, {
          gasLimit: 1e7
        }).catch(e => decodeRevertReason(e)))
          .to.include('TokenPaymaster: no balance')
        expect(await entryPoint.handleOps([op], beneficiaryAddress, {
          gasLimit: 1e7
        }).catch(e => decodeRevertReason(e)))
          .to.include('TokenPaymaster: no balance')
      })
    })

    describe('create account', () => {
      let createOp: PackedUserOperation
      let created = false
      const beneficiaryAddress = createAddress()

      it('should reject if account not funded', async () => {
        const op = await fillSignAndPack({
          initCode: getAccountDeployer(entryPoint.address, accountOwner.address, 1),
          verificationGasLimit: 1e7,
          paymaster: paymaster.address,
          paymasterPostOpGasLimit: 3e5
        }, accountOwner, entryPoint)
        expect(await entryPoint.callStatic.handleOps([op], beneficiaryAddress, {
          gasLimit: 1e7
        }).catch(e => decodeRevertReason(e)))
          .to.include('TokenPaymaster: no balance')
      })

      it('should succeed to create account with tokens', async () => {
        createOp = await fillSignAndPack({
          initCode: getAccountDeployer(entryPoint.address, accountOwner.address, 3),
          verificationGasLimit: 2e6,
          paymaster: paymaster.address,
          paymasterPostOpGasLimit: 3e5,
          nonce: 0
        }, accountOwner, entryPoint)

        const preAddr = createOp.sender
        await paymaster.mintTokens(preAddr, parseEther('1'))
        // paymaster is the token, so no need for "approve" or any init function...

        // const snapshot = await ethers.provider.send('evm_snapshot', [])
        await simulateValidation(createOp, entryPoint.address, { gasLimit: 5e6 })
        // TODO: can't do opcode banning with EntryPointSimulations (since its not on-chain) add when we can debug_traceCall
        // const [tx] = await ethers.provider.getBlock('latest').then(block => block.transactions)
        // await checkForBannedOps(tx, true)
        // await ethers.provider.send('evm_revert', [snapshot])

        const rcpt = await entryPoint.handleOps([createOp], beneficiaryAddress, {
          gasLimit: 1e7
        }).catch(rethrow()).then(async tx => await tx!.wait())
        console.log('\t== create gasUsed=', rcpt.gasUsed.toString())
        await calcGasUsage(rcpt, entryPoint)
        created = true
      })

      it('account should pay for its creation (in tst)', async function () {
        if (!created) this.skip()
        // TODO: calculate needed payment
        const ethRedeemed = await getBalance(beneficiaryAddress)
        expect(ethRedeemed).to.above(100000)

        const accountAddr = await getAccountAddress(accountOwner.address, factory)
        const postBalance = await getTokenBalance(paymaster, accountAddr)
        expect(1e18 - postBalance).to.above(10000)
      })

      it('should reject if account already created', async function () {
        if (!created) this.skip()
        await expect(entryPoint.callStatic.handleOps([createOp], beneficiaryAddress, {
          gasLimit: 1e7
        }).catch(rethrow())).to.revertedWith('sender already constructed')
      })

      it('batched request should each pay for its share', async function () {
        this.timeout(20000)
        // validate context is passed correctly to postOp
        // (context is the account to pay with)

        const beneficiaryAddress = createAddress()
        const testCounter = await new TestCounter__factory(ethersSigner).deploy()
        const justEmit = testCounter.interface.encodeFunctionData('justemit')
        const execFromSingleton = account.interface.encodeFunctionData('execute', [testCounter.address, 0, justEmit])

        const ops: PackedUserOperation[] = []
        const accounts: SimpleAccount[] = []

        for (let i = 0; i < 4; i++) {
          const { proxy: aAccount } = await createAccount(ethersSigner, await accountOwner.getAddress(), entryPoint.address)
          await paymaster.mintTokens(aAccount.address, parseEther('1'))
          const op = await fillSignAndPack({
            sender: aAccount.address,
            callData: execFromSingleton,
            paymaster: paymaster.address,
            paymasterPostOpGasLimit: 3e5
          }, accountOwner, entryPoint)

          accounts.push(aAccount)
          ops.push(op)
        }

        const pmBalanceBefore = await paymaster.balanceOf(paymaster.address).then(b => b.toNumber())
        await entryPoint.handleOps(ops, beneficiaryAddress).then(async tx => tx.wait())
        const totalPaid = await paymaster.balanceOf(paymaster.address).then(b => b.toNumber()) - pmBalanceBefore
        for (let i = 0; i < accounts.length; i++) {
          const bal = await getTokenBalance(paymaster, accounts[i].address)
          const paid = parseEther('1').sub(bal.toString()).toNumber()

          // roughly each account should pay 1/4th of total price, within 15%
          // (first account pays more, for warming up..)
          expect(paid).to.be.closeTo(totalPaid / 4, paid * 0.15)
        }
      })

      // accounts attempt to grief paymaster: both accounts pass validatePaymasterUserOp (since they have enough balance)
      // but the execution of account1 drains account2.
      // as a result, the postOp of the paymaster reverts, and cause entire handleOp to revert.
      describe('grief attempt', () => {
        let account2: SimpleAccount
        let approveCallData: string
        before(async function () {
          this.timeout(20000);
          ({ proxy: account2 } = await createAccount(ethersSigner, await accountOwner.getAddress(), entryPoint.address))
          await paymaster.mintTokens(account2.address, parseEther('1'))
          await paymaster.mintTokens(account.address, parseEther('1'))
          approveCallData = paymaster.interface.encodeFunctionData('approve', [account.address, ethers.constants.MaxUint256])
          // need to call approve from account2. use paymaster for that
          const approveOp = await fillSignAndPack({
            sender: account2.address,
            callData: account2.interface.encodeFunctionData('execute', [paymaster.address, 0, approveCallData]),
            paymaster: paymaster.address,
            paymasterPostOpGasLimit: 3e5
          }, accountOwner, entryPoint)
          await entryPoint.handleOps([approveOp], beneficiaryAddress)
          expect(await paymaster.allowance(account2.address, account.address)).to.eq(ethers.constants.MaxUint256)
        })

        it('griefing attempt in postOp should cause the execution part of UserOp to revert', async () => {
          // account1 is approved to withdraw going to withdraw account2's balance

          const account2Balance = await paymaster.balanceOf(account2.address)
          const transferCost = parseEther('1').sub(account2Balance)
          const withdrawAmount = account2Balance.sub(transferCost.mul(0))
          const withdrawTokens = paymaster.interface.encodeFunctionData('transferFrom', [account2.address, account.address, withdrawAmount])
          const execFromEntryPoint = account.interface.encodeFunctionData('execute', [paymaster.address, 0, withdrawTokens])

          const userOp1 = await fillSignAndPack({
            sender: account.address,
            callData: execFromEntryPoint,
            paymaster: paymaster.address,
            paymasterPostOpGasLimit: 3e5
          }, accountOwner, entryPoint)

          // account2's operation is unimportant, as it is going to be reverted - but the paymaster will have to pay for it.
          const userOp2 = await fillSignAndPack({
            sender: account2.address,
            callData: execFromEntryPoint,
            paymaster: paymaster.address,
            paymasterPostOpGasLimit: 3e5,
            callGasLimit: 1e6
          }, accountOwner, entryPoint)

          const rcpt =
            await entryPoint.handleOps([
              userOp1,
              userOp2
            ], beneficiaryAddress)

          const transferEvents = await paymaster.queryFilter(paymaster.filters.Transfer(), rcpt.blockHash)
          const [log1, log2] = await entryPoint.queryFilter(entryPoint.filters.UserOperationEvent(), rcpt.blockHash)
          expect(log1.args.success).to.eq(true)
          expect(log2.args.success).to.eq(false)
          expect(transferEvents.length).to.eq(2)
        })
      })
    })
    describe('withdraw', () => {
      const withdrawAddress = createAddress()
      it('should fail to withdraw before unstake', async function () {
        this.timeout(20000)
        await expect(
          paymaster.withdrawStake(withdrawAddress)
        ).to.revertedWith('must call unlockStake')
      })
      it('should be able to withdraw after unstake delay', async () => {
        await paymaster.unlockStake()
        const amount = await entryPoint.getDepositInfo(paymaster.address).then(info => info.stake)
        expect(amount).to.be.gte(ONE_ETH.div(2))
        await ethers.provider.send('evm_mine', [Math.floor(Date.now() / 1000) + 1000])
        await paymaster.withdrawStake(withdrawAddress)
        expect(await ethers.provider.getBalance(withdrawAddress)).to.eql(amount)
        expect(await entryPoint.getDepositInfo(paymaster.address).then(info => info.stake)).to.eq(0)
      })
    })
  })
})
