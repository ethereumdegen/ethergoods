TODO:

1. Write tests
2. Deploy to Ropsten using testnet coins
3. Write JS and use metamask to register a new Good, all on ropsten
4.



## HOW TO TEST

npm install -g ethereumjs-testrpc  (https://github.com/ethereumjs/testrpc)
testrpc

truffle test


##publish to RPOSTEN
1. Make an account with geth --testnet account new  and load it up with eth


2. run geth with
    geth --testnet --fast --rpc --rpcapi eth,net,web3,personal

    geth attach http://127.0.0.1:8545


    personal.unlockAccount(eth.accounts[0])

3. truffle migrate --network ropsten
