# Exploring Simpler Ethereum Multisig Contracts

![](https://github.com/christianlundkvist/blog/blob/master/2017_08_11_exploring_simpler_multisig_contracts/files/keys.jpg?raw=true)

*Christian Lundkvist, 2017-08-11*

A couple of weeks ago a number of widely used Ethereum multisig wallets [were hacked](https://blog.ethcore.io/the-multi-sig-hack-a-postmortem/), to the tune of ~$32 million in Ethereum-based assets stolen. Another ~$160 million in assets [were preemptively taken and safeguarded](https://www.reddit.com/r/ethereum/comments/6povrc/the_whg_has_returned_95_of_the_funds_and_now_hold/) by a group of white-hat hackers.

The incident highlights the challenges with writing smart contract code. You can hardly think of a more adversarial environment than a public blockchain: Your code runs open to the world and anyone can try to poke and prod the functions you expose. Add to that contracts that safeguard tens of millions of dollars worth of assets and you have a situation where hackers are very motivated to find flaws in your contracts and exploit them.

The irony about these multisig wallet hacks is that multisig wallets are supposed to be safer than just using one private key. In theory the multisig nature makes it harder for a hacker since they need to hack several people to obtain multiple private keys. In this case however the logic implementing this security feature had a bug which made the security much worse than a single key.

# Simplicity vs Security

There is an interesting tradeoff here: More logic in smart contracts can be used to implement more security features: timeouts, [spending limits](https://ethereum.stackexchange.com/questions/1261/mist-multisig-wallet-how-to-change-daily-withdrawal-limit), multisig, [vaults](http://hackingdistributed.com/2016/02/26/how-to-implement-secure-bitcoin-vaults/) etc. However, the more logic in the smart contract the bigger the attack surface and the more likely that bugs are introduced that risk undermining the security features.

![](https://github.com/christianlundkvist/blog/blob/master/2017_08_11_exploring_simpler_multisig_contracts/files/key_in_drawer.jpg?raw=true)

We can consider a spectrum of asset-management tools from simplest to more complex. The simplest way to secure your Ether is to use a single private key which corresponds to an Ethereum address, sometimes known as an "End-user Owned Account". With this method there is no smart contract logic at all to worry about, so we've eliminated that risk. However, just using a single key also means you have a single point of failure.

At the other end of the spectrum you can create very elaborate wallet contracts to manage your funds. The Ethereum Foundation has one [wallet contract](https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol) that they actively use & recently Gnosis introduced a [sophisticated multisig wallet](https://wallet.gnosis.pm) supporting spending limits, administrative controls and using a workflow where owners confirm transactions that are submitted by others.

# A simple multisig contract

![](https://github.com/christianlundkvist/blog/blob/master/2017_08_11_exploring_simpler_multisig_contracts/files/2manrule.png?raw=true)

We wanted to explore what the simplest possible multisig contract could look like. It should have the ability for a threshold of key holders to come together and move funds, but to maintain simplicity we do not want more advanced features like spending limits or the ability to update the signers.

The inspiration is how multisig is done in Bitcoin, where it is supported directly in the scripting language as an opcode, `OP_CHECKMULTISIG`. To date I'm aware of no case of Bitcoin being stolen or lost due to a faulty Bitcoin multisig script.

What we ended up with was a contract that pushes most logic off-chain, where each multisig owner is responsible for creating the signature that authorizes transactions and then a single function is used to present all the signatures to the contract to be verified. We use the proposed [ERC191 specification](https://github.com/ethereum/EIPs/issues/191) which is an attempt at standardizing the format of the signatures. A single integer nonce is used to prevent replay attacks.

In terms of user interface the idea is that each multisig keyholder would have a UI where they enter in the details of the transaction they wish to send (ideally on an offline computer). Then on an online machine an "operator" would gather up all the signatures from the keyholder and send off the actual transaction containing all the signatures. The operator would not need to have any actual control of funds, the multisig key holders are ultimately the ones that have the authority to execute transactions.

The complete code is presented here:

```
pragma solidity 0.4.11;
contract SimpleMultiSig {

  uint public nonce;                // (only) mutable state
  uint public threshold;            // immutable state
  mapping (address => bool) isOwner; // immutable state
  address[] public ownersArr;        // immutable state

  function SimpleMultiSig(uint threshold_, address[] owners_) {
    if (owners_.length > 10 || threshold_ > owners_.length || threshold_ == 0) {throw;}

    for (uint i=0; i<owners_.length; i++) {
      isOwner[owners_[i]] = true;
    }
    ownersArr = owners_;
    threshold = threshold_;
  }

  // Note that address recovered from signatures must be strictly increasing
  function execute(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data) {
    if (sigR.length != threshold) {throw;}
    if (sigR.length != sigS.length || sigR.length != sigV.length) {throw;}

    // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
    bytes32 txHash = sha3(byte(0x19), byte(0), this, destination, value, data, nonce);

    address lastAdd = address(0); // cannot have address(0) as an owner
    for (uint i = 0; i < threshold; i++) {
        address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
        if (recovered <= lastAdd || !isOwner[recovered]) throw;
        lastAdd = recovered;
    }

    // If we make it here all signatures are accounted for
    nonce = nonce + 1;
    if (!destination.call.value(value)(data)) {throw;}
  }

  function () payable {}
}
```

and the code is also available at the following [github repository](https://github.com/christianlundkvist/simple-multisig).

## Benefits

Some beneficial properties of this contract are

* Minimal codebase: Only 40 lines of code
* Minimal mutable state: The only mutable data is a single `uint` incrementing on each execution
* Minimal interface: Interface consists of a single function
* Can send arbitrary transactions, so supports tokens

The lack of complex state transitions makes it impossible for the contract to end up in a "frozen" state with funds inaccessible, such as is [described here](http://hackingdistributed.com/2017/07/20/parity-wallet-not-alone/) by Emin Gün Sirer. Since the only possible state transition is a simple incrementing counter the contract will always be in a correct state. The counter is not likely to overflow since a 32 byte integer is used. Also testing is made easier by the fact that there is only one function to test (apart from the constructor).

Since we've made the on-chain logic as simple as possible the complexity increases in the off-chain workflow, which leads to the following downsides:

* Needs the user to sign non-transaction data, which may preclude using some hardware wallets
* End users need to coordinate off-chain in order to send a transaction


# Future work: Formal verification

![](https://github.com/christianlundkvist/blog/blob/master/2017_08_11_exploring_simpler_multisig_contracts/files/cyber.jpg?raw=true)

The simplicity of the contract might make it a good candidate for creating a formal specification and performing a formal verification using that spec - mathematically proving that the code follows the specification. This may require rewriting the contract in a language where the compilation to EVM has been formally verified as well. Formal verification of the EVM is getting more attention recently with the recent [release of a formal semantics for the EVM](https://www.ideals.illinois.edu/handle/2142/97207).

Another next step could be to write the simple multisig contract in LLL or even pure EVM bytecode in order to limit risks from the Solidity compiler.

# Summary

This post explored a simpler type of multisig Ethereum contract, in which detached signatures are aggregated off-chain before sending them all in one transaction. This simplifies the on-chain smart contract code to make it easier to review and opens the possibility for performing formal verification in the future.

*Thanks to Nate Rush for suggestions on improving the contract.*
