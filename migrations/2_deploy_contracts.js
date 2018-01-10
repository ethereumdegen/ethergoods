var GoodToken = artifacts.require("./GoodToken.sol");
var TokenMarket = artifacts.require("./BasicNFTTokenMarket.sol");
var EtherGoods = artifacts.require("./EtherGoods.sol");

module.exports = function(deployer) {
  deployer.deploy(GoodToken);
  deployer.deploy(TokenMarket);
  deployer.deploy(EtherGoods);
};
