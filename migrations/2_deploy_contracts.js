var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./EtherGoods.sol");

module.exports = function(deployer) {
  deployer.deploy(EtherGoods);
};
