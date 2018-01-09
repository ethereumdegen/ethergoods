pragma solidity ^0.4.8;


import './GOODToken.sol';  //NFT

// see https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts

// see https://github.com/decentraland/land/tree/master/contracts


contract EtherGoods {

    address contractOwner;

    string public standard = 'EtherGoods';
    string public name;
    string public version;

    // GOODToken contract that holds the registry of good instances
    GOODToken public goods;

    //allows users to buy and sell the NFT tokens
    BasicNFTTokenMarket public goodTokenMarket;
    goodTokenMarket.setTokenContract(goods);
     

    //blueprint for a good
    struct GoodType {
       bytes32 typeId; //the id of the asset blueprint
       address creator;
       uint16 totalSupply;
       uint16 nextSupplyIndexToSell;
       string description;
       bool initialized;
       uint claimPrice; // can be changed by owner
       bool claimsEnabled; // can be changed by owner
   }



    mapping (bytes32 => GoodType) goodTypes;


    // https://github.com/ethereum/eips/issues/721
    //mapping (bytes32 => Good) goods;




    mapping (address => uint) public pendingWithdrawals;

		event RegisterGood(address indexed to, bytes32 goodHash);
		event RegistrationTransfer(address indexed from, address indexed to, bytes32 goodHash);
		event ModifyClaimsEnable(address indexed owner,bool enabele,bytes32 goodHash);
    event ModifyClaimsPrice(address indexed owner,uint price,bytes32 goodHash);
    event ModifyGoodDescription(address indexed owner,string description,bytes32 goodHash);


    event ClaimGood(address indexed to, bytes32 goodHash, uint32 supplyIndex);
    event TransferSupply(bytes32 indexed typeId,address indexed from, address indexed to, uint amount);

  	event SupplyOffered(bytes32 indexed typeId, uint minValue, address indexed toAddress);
    event SupplyBidEntered(bytes32 indexed typeId, uint value, address indexed fromAddress);
    event SupplyBidWithdrawn(bytes32 indexed typeId, uint value, address indexed fromAddress);
		event SupplyBought(bytes32 indexed typeId,  uint value, address fromAddress, address indexed toAddress);
		event SupplySold(bytes32 indexed typeId, uint value, address indexed fromAddress, address toAddress);
			//cant index enough !

  	event SupplyNoLongerForSale(bytes32 indexed typeId);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthergoodsMarket() payable {
        owner = msg.sender;
        name = "ETHERGOODS";                                 // Set the name for display purposes
        version = "0.2.2";
    }


		function registerNewGoodType( string name, string description, uint16 totalSupply, uint claimPrice )
		{
      if(bytes(name).length > 32) revert();
      bytes32 typeId = stringToBytes32(name);

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

			goodgoodTypess[typeId].claimPrice = claimPrice; //price in wei to buy an instance
      goodTypes[typeId].claimsEnabled = true; //owners switch for allowing sales

			RegisterGood(msg.sender,typeId);
		}

    function stringToBytes32(string memory source) returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function setGoodTypeDescription(string description, bytes32 typeId)
		{
				if(!goodTypes[typeId].initialized) revert();
				if (goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].description = description;

				ModifyGoodTypeDescription(msg.sender,description,typeId);

		}

		//modifying existing goods registrations
		function setClaimsEnabled(bool enabled, bytes32 typeId)
		{
				if(!goodTypes[typeId].initialized) revert();
				if (goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].claimsEnabled = enabled;

				ModifyClaimsEnable(msg.sender,enabled,typeId);

		}

		function setClaimsPrice(uint claimPrice, bytes32 typeId)
		{
				if(!goodTypes[typeId].initialized) revert();
				if(goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it
        if(claimPrice < 0) revert();

				goodTypes[typeId].claimPrice = claimPrice;

				ModifyClaimsPrice(msg.sender,claimPrice,typeId);

		}

		function transferRegistration(address to, bytes32 typeId)
		{
				if(!goodTypes[typeId].initialized) revert();
				if(goodTypes[typeId].creator != msg.sender) revert(); //must own the registration to transfer it

				goodTypes[typeId].creator = to;

				RegistrationTransfer(msg.sender,to,uniqueHash);

		}



       //uniqueHash =typeId
		function claimGood(bytes32 typeId) payable
		{
			if(!goodTypes[typeId].initialized) revert(); //if the good isnt registered
			if(goodTypes[typeId].nextSupplyIndexToSell >= goodTypes[typeId].totalSupply) revert(); // the good is all claimed

      if (msg.value < goodTypes[typeId].claimPrice) revert();
      if (goodTypes[typeId].claimPrice < 0) revert();
      if (msg.value < 0) revert();
      if (goods.exists(typeId, goods[typeId].nextSupplyIndexToSell)) revert();

		//	goods[typeId].supplyIndexToAddress[goods[typeId].nextSupplyIndexToSell] = msg.sender;

    //  goods[typeId].balanceOf[msg.sender]++;
      goods.claimGoodToken(typeId,goods[typeId].nextSupplyIndexToSell);


      //Content creator gets claim eth
      pendingWithdrawals[goods[typeId].creator] += goodTypes[typeId].claimPrice

      //refund overspends
      pendingWithdrawals[goods[typeId].creator] += (msg.value - goodTypes[typeId].claimPrice)


			ClaimGood(msg.sender, typeId, goods[typeId].nextSupplyIndexToSell );

			goods[typeId].nextSupplyIndexToSell++;


		}




    function withdrawPendingBalance()
    {
      if( pendingWithdrawals[msg.sender] <= 0 ) revert();

      msg.sender.transfer( pendingWithdrawals[msg.sender] );

      pendingWithdrawals[msg.sender] = 0;
    }


}
