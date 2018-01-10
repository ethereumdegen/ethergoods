pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EtherGoods.sol";
import "../contracts/GoodToken.sol";
import "../contracts/BasicNFTTokenMarket.sol";


contract TestEtherGoods {

  function testInitialBalanceUsingDeployedContract() {
    EtherGoods meta = EtherGoods(DeployedAddresses.EtherGoods());


  //  Assert.equal(meta.name, "ETHERGOODS", "Deployed contract has a name");
  }

  /*
  function testInitialBalanceWithNewMetaCoin() {
    MetaCoin meta = new MetaCoin();

    uint expected = 10000;

    Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  }
  */

}
