var ConvertLib = artifacts.require("./ConvertLib.sol");
var EtherGoods = artifacts.require("./EtherGoods.sol");

module.exports = function(deployer) {
  deployer.deploy(EtherGoods);
};
