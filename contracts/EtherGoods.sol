pragma solidity ^0.4.8;


import './GOODToken.sol';  //NFT
import './BasicNFTTokenMarket.sol';
// see https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts

// see https://github.com/decentraland/land/tree/master/contracts


contract EtherGoods {

    address owner;

  //  string public standard = 'EtherGoods';
    string public name = 'EtherGoods';
    string public version;

    // GOODToken contract that holds the registry of good instances
    GoodToken public goods;

    //allows users to buy and sell the NFT tokens
    BasicNFTTokenMarket public goodTokenMarket;
  //  goodTokenMarket.setTokenContract(goods);


    //blueprint for a good
    struct GoodType {
       uint256 typeId; //the id of the asset blueprint
       address creator;
       uint16 totalSupply;
       uint16 nextSupplyIndexToSell;
       string description;
       bool initialized;
       uint claimPrice; // can be changed by owner
       bool claimsEnabled; // can be changed by owner
   }



    mapping (uint256 => GoodType) goodTypes;


    // https://github.com/ethereum/eips/issues/721
    //mapping (bytes32 => Good) goods;




    mapping (address => uint) public pendingWithdrawals;

		event RegisterGood(address indexed to, uint256 typeId);
		event RegistrationTransfer(address indexed from, address indexed to, uint256 typeId);
		event ModifyClaimsEnable(address indexed owner,bool enabele,uint256 typeId);
    event ModifyClaimsPrice(address indexed owner,uint price,uint256 typeId);
    event ModifyGoodTypeDescription(address indexed owner,string description,uint256 typeId);


    event ClaimGood(address indexed to, uint256 goodHash, uint256 supplyIndex);
	//cant index enough !


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthergoodsMarket() public payable {
        owner = msg.sender;
        name = "ETHERGOODS";                                 // Set the name for display purposes
        version = "0.2.2";
    }


		function registerNewGoodType( string name, string description, uint16 totalSupply, uint claimPrice ) public
		{
    //  if(bytes(name).length > 32) revert();
      uint256 typeId = uint256(keccak256( name ));

			//make sure the goodtype doesnt exist
			if(goodTypes[typeId].initialized) revert();
			if(totalSupply < 1) revert();
			if(claimPrice < 0) revert();

			goodTypes[typeId].initialized = true;
			goodTypes[typeId].creator = msg.sender; //usually msg.sender

			goodTypes[typeId].totalSupply = totalSupply;
			goodTypes[typeId].nextSupplyIndexToSell = 0;
      goodTypes[typeId].typeId = typeId;
      goodTypes[typeId].description = description;

			goodTypes[typeId].claimPrice = claimPrice; //price in wei to buy an instance
      goodTypes[typeId].claimsEnabled = true; //owners switch for allowing sales

			RegisterGood(msg.sender,typeId);
		}

  /*  function stringToBytes32(string memory source) public returns (bytes32 result)  {
        assembly {
            result := mload(add(source, 32))
        }
    }*/

    function setGoodTypeDescription(string description, uint256 typeId) public
		{
				if(!goodTypes[typeId].initialized) revert();
				if (goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].description = description;

				ModifyGoodTypeDescription(msg.sender,description,typeId);

		}

		//modifying existing goods registrations
		function setClaimsEnabled(bool enabled, uint256 typeId) public
		{
				if(!goodTypes[typeId].initialized) revert();
				if (goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].claimsEnabled = enabled;

				ModifyClaimsEnable(msg.sender,enabled,typeId);

		}

		function setClaimsPrice(uint claimPrice, uint256 typeId) public
		{
				if(!goodTypes[typeId].initialized) revert();
				if(goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it
        if(claimPrice < 0) revert();

				goodTypes[typeId].claimPrice = claimPrice;

				ModifyClaimsPrice(msg.sender,claimPrice,typeId);

		}

		function transferRegistration(address to, uint256 typeId) public
		{
				if(!goodTypes[typeId].initialized) revert();
				if(goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].creator = to;

				RegistrationTransfer(msg.sender,to,typeId);

		}



       //uniqueHash =typeId
		function claimGood(uint256 typeId) public payable
		{
			if(!goodTypes[typeId].initialized) revert(); //if the good isnt registered
			if(goodTypes[typeId].nextSupplyIndexToSell >= goodTypes[typeId].totalSupply) revert(); // the good is all claimed

      if (msg.value < goodTypes[typeId].claimPrice) revert();
      if (goodTypes[typeId].claimPrice < 0) revert();
      if (msg.value < 0) revert();
      if (goods.exists(typeId, goodTypes[typeId].nextSupplyIndexToSell)) revert();

      string memory metadata;
	    goods.claimGoodToken(msg.sender,goods.buildTokenId(typeId,goodTypes[typeId].nextSupplyIndexToSell),metadata);

      //Content creator gets claim eth
      pendingWithdrawals[goodTypes[typeId].creator] += goodTypes[typeId].claimPrice;

      //refund overspends   CHECK ME FOR BUGS LIKE OVERFLOW

      pendingWithdrawals[goodTypes[typeId].creator] += (msg.value - goodTypes[typeId].claimPrice);


			ClaimGood(msg.sender, typeId, goodTypes[typeId].nextSupplyIndexToSell );

			goodTypes[typeId].nextSupplyIndexToSell++;


		}




    function withdrawPendingBalance() public
    {
      if( pendingWithdrawals[msg.sender] <= 0 ) revert();

      msg.sender.transfer( pendingWithdrawals[msg.sender] );

      pendingWithdrawals[msg.sender] = 0;
    }


}
