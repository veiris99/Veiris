# README #



### What is this repository for?

* Veiris token allocation contract
* ver 1.0
* for crowd funding during the pre and ICO phase


### How do I get set up? 

* Use truffle, Ethereum Wallet or Remix to deploy contract on Ethereum network.
* First deploy "Allocate" contract and obtain its address. 
* Secondly deploy "Token" contract and use address from previous step as its input. Obtain address of the token contract. 
* Thirdly call function updateTokenAddress() of "Allocate" contract and provide address from Token contract as input.


### How do I run

* owner can allocate tokens to users by calling function **allocate()**. Argument provided to the function is an address of token recipient and amount of tokens to transfer. Tokens passed should take into account number of decimals. E.g if 10 tokens are allocated to the account, number representing 10 tokens is 10 plus 8 zeros and appears like this **1000000000**.

* Token recipient can claim their tokens by sending 0 ether transaction to the **Allocate** contract. Most useful way of calling this function is either through **MyEtherWallet** or **Metamask**.

* In order for token recipients to be able to claim their token, contract owner has to call **updateClaimStatus()** and pass number **1** as an argument to set  the flag **claimingEnabled** to true.

* There are other functions in contract available which owner can use.

* During contract creation all tokens are allocated to **Allocate** contract. If those tokens are not distributed to specific accounts for allocation, owner can call **tokenDrain()** function and pass as an argument an Ethereum address to which all tokens will be transferred.

* In case any unintended ether has been sent to this contract, owner can call function **drain()** and pass as an argument an Ethereum address to which all Ether will be transferred.

* Owner can claim tokens for user calling function **adminClaimTokenForUser()** in case user has difficulties claiming it themselves. Owner needs to pass address of the recipient as an argument.

* After initial deployment token contract is set to block transaction of tokens by token owners. This is useful when contract owner wants to disable trading of tokens before all recipients claimed their tokens or before e.g. tokens can be vested if such period is part of the plan. Owner is allowed to transfer tokens while they are in locked status. 

To unblock tokens and allow to be transfered by any token owner, contract owner needs to call function **unlock()** to make tokens transferable. To lock tokens again, owner can call function **lock()**.

* Allocation is designed in such a way that owner can allocate tokens several times to the same account. Token recipient can claim their tokens at any time and contract will keep track of tokens already claimed and will only release tokens which were not claimed to this moment. 



