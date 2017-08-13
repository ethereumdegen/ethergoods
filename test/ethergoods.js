var EtherGoods = artifacts.require("./EtherGoods.sol");
var sha3_256 = require('js-sha3').sha3_256;

contract('EtherGoods', function(accounts) {

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
