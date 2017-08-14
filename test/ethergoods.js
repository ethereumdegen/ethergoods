var EtherGoods = artifacts.require("./EtherGoods.sol");

var ethUtil =  require('ethereumjs-util');


/*
  var expectThrow = async function (promise) {
    try {
      await promise;
    } catch (error) {
      // TODO: Check jump destination to destinguish between a throw
      //       and an actual invalid jump.
      const invalidOpcode = error.message.search('invalid opcode') >= 0;
      const invalidJump = error.message.search('invalid JUMP') >= 0;
      // TODO: When we contract A calls contract B, and B throws, instead
      //       of an 'invalid jump', we get an 'out of gas' error. How do
      //       we distinguish this from an actual out of gas event? (The
      //       testrpc log actually show an 'invalid jump' event.)
      const outOfGas = error.message.search('out of gas') >= 0;
      assert(
        invalidOpcode || invalidJump || outOfGas,
        "Expected throw, got '" + error + "' instead",
      );
      return;
    }
    assert.fail('Expected throw not received');
  }; */


contract('EtherGoods', function(accounts) {





/*
  it("should register a new good", function() {
    return EtherGoods.deployed().then(function(instance) {
    //  return instance.getBalance.call(accounts[0]);

      var unique_hash = sha3_256("canoeasset");
      return instance.registerNewGood.call(accounts[0],unique_hash,"canoe","A wooden boat",5,400);
    }).then(function(response) {
      var unique_hash = sha3_256("canoeasset");
      assert.equal(response.initialized, true, "Good is registered");
    });
  });
  */

  it("can register a good", async function () {
  var contract = await EtherGoods.deployed();

  var unique_hash = ethUtil.bufferToHex(ethUtil.sha3("canoeasset"));
  console.log('sha3')
  console.log(unique_hash)


  await contract.registerNewGood(accounts[0],unique_hash,"canoe","A wooden boat",5,400);


  var good_record = await contract.goods.call(unique_hash);

  console.log("Record");
   console.log("Good: " + good_record);

  assert.equal(true, good_record[0]);

}),

it("can claim a good", async function () {
  var contract = await EtherGoods.deployed();

  var unique_hash = ethUtil.bufferToHex(ethUtil.sha3("canoeasset"));
  await contract.claimGood(unique_hash);
  await contract.claimGood(unique_hash);
  await contract.claimGood(unique_hash);

  var good_record = await contract.goods.call(unique_hash);

  var balance_of = await contract.getSupplyBalance.call(unique_hash,accounts[0]);

    console.log("balance");
    console.log(balance_of);
      console.log(balance_of['c'][0]);

  var balance_of_value = balance_of['c'][0];

  assert.equal(3, balance_of_value );

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
