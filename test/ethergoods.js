var GoodToken = artifacts.require("./GoodToken.sol");
var TokenMarket = artifacts.require("./BasicNFTTokenMarket.sol");
var EtherGoods = artifacts.require("./EtherGoods.sol");

var ethUtil =  require('ethereumjs-util');
var web3 =  require('web3');
var solidityHelper =  require('./solidity-helper');

//https://web3js.readthedocs.io/en/1.0/web3-utils.html
//https://medium.com/@valkn0t/3-things-i-learned-this-week-using-solidity-truffle-and-web3-a911c3adc730

contract('EtherGoods', function(accounts) {


    it("can deploy ", async function () {

      console.log( 'deploying token' )
      var tokenContract = await GoodToken.deployed();
          console.log( 'deployed token' )

      var marketContract = await TokenMarket.deployed();
      var contract = await EtherGoods.deployed();



    await marketContract.setTokenContractAddress(accounts[0],tokenContract);
    await contract.setMarketContractAddress(accounts[0],marketContract);
    await contract.setTokenContractAddress(accounts[0],tokenContract);



  }),

  it("can register a good", async function () {


<<<<<<< HEAD
//  var unique_hash = ethUtil.bufferToHex(ethUtil.sha3("canoeasset"));
//  console.log('sha3')
//  console.log(unique_hash)


//canoe

//7.3426930413956622283065143620738574142638959639431768834166324387693517887725e+76)


=======
  var tokenContract = await GoodToken.deployed();
  var marketContract = await TokenMarket.deployed();
  var contract = await EtherGoods.deployed();
>>>>>>> 3d58dfdfa4939c35306f15236842ab8137c81cd9

  await marketContract.setTokenContractAddress(accounts[0],tokenContract);
  await contract.setMarketContractAddress(accounts[0],marketContract);
  await contract.setTokenContractAddress(accounts[0],tokenContract);
  await tokenContract.setMasterContractAddress(accounts[0],contract)

  var passName= "canoe";

  await contract.registerNewGoodType(passName,5,400);

  var passNameBytes32 = solidityHelper.stringToSolidityBytes32(passName)
  const nameHash  = web3.utils.sha3(web3.utils.toHex(passNameBytes32), {encoding:"hex"});

  var good_type_record = await contract.goodTypes.call(nameHash);

  console.log("Record");
   console.log("Good Type: " + good_type_record);


  assert.equal(true, good_type_record[7] ); //initialized

  var typeIdHex = good_type_record[5];

  assert.equal('0x63616e6f65000000000000000000000000000000000000000000000000000000', typeIdHex);

  var typeId =  web3.utils.toBN(typeIdHex);

  console.log("typeId: " + typeId);



//  await contract.claimGood(typeId).send({from: '0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe',value: 1000});//,{value: 1000}
//  var token_record = await contract.goods.call(typeId);

//  assert.equal(true, token_record ); //initialized

}),

it("can bid on the market", async function () {

  var tokenContract = await GoodToken.deployed();
  var marketContract = await TokenMarket.deployed();
  var contract = await EtherGoods.deployed();

  await marketContract.setTokenContractAddress(accounts[0],tokenContract);
  await contract.setMarketContractAddress(accounts[0],marketContract);
  await contract.setTokenContractAddress(accounts[0],tokenContract);
  await tokenContract.setMasterContractAddress(accounts[0],contract)





/*

var contract = await EtherGoods.deployed();

  var unique_hash = ethUtil.bufferToHex(ethUtil.sha3("canoeasset"));
  await contract.claimGood(unique_hash);


  var good_record = await contract.goods.call(unique_hash);

  var balance_of = await contract.getSupplyBalance.call(unique_hash,accounts[0]);

    console.log("balance");
    console.log(balance_of);
      console.log(balance_of['c'][0]);

  var balance_of_value = balance_of['c'][0];

  assert.equal(3, balance_of_value );
*/
}),



/*
  it("can not buy a punk with an invalid index", async function () {
      var contract = await CryptoPunksMarket.deployed();
      await expectThrow(contract.claimGood(100000));
    }),
    */

  it("can not get supply while supply all taken", async function () {
      var contract = await EtherGoods.deployed();
      var balance = await contract.balanceOf.call(accounts[0]);
      console.log("Pre Balance: " + balance);

      var allAssigned = await contract.allPunksAssigned.call();
      console.log("All assigned: " + allAssigned);
      assert.equal(false, allAssigned, "allAssigned should be false to start.");
      await expectThrow(contract.getPunk(0));
      var balance = await contract.balanceOf.call(accounts[0]);
      console.log("Balance after fail: " + balance);
    });

/*
  it("should send coin correctly", function() {
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return MetaCoin.deployed().then(function(instance) {
      meta = instance;
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, {from: account_one});
    }).then(function() {
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });

  */
});
