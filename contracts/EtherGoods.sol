pragma solidity ^0.4.8;


import './GoodToken.sol';  //NFT
import './BasicNFTTokenMarket.sol';
// see https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts

// see https://github.com/decentraland/land/tree/master/contracts


contract EtherGoods is Ownable {

    //address public owner;

  //  string public standard = 'EtherGoods';
    string public name = 'EtherGoods';
    string public version;

    bool public hasTokenContract = false;
    bool public hasMarketContract = false;

    bool public lockTokenContract = false;
    bool public lockMarketContract = false;


    // GOODToken contract that holds the registry of good instances
    GoodToken public goods;

    //allows users to buy and sell the NFT tokens
    BasicNFTTokenMarket public goodTokenMarket;
  //  goodTokenMarket.setTokenContract(goods);


    //blueprint for a good
    struct GoodType {
       uint256 typeId; //the id of the asset blueprint
       address creator;
       uint256 totalSupply;
       uint256 nextSupplyIndexToSell;
       uint256 claimPrice; // can be changed by owner
       bytes32  name;
       string description;
       bool initialized;
       bool claimsEnabled; // can be changed by owner
   }



    mapping (uint256 => GoodType) public goodTypes;


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



    function setTokenContractAddress(address _address) external onlyOwner {
        if(lockTokenContract) revert();
        GoodToken goodTokenContract = GoodToken(_address);
        // Set the new contract address
        goods = goodTokenContract;
        hasTokenContract = true;
    }

    function lockTokenContractAddress() external onlyOwner {
        if(!hasTokenContract) revert();
        lockTokenContract = true;
    }

    function setMarketContractAddress(address _address) external onlyOwner {
        if(lockMarketContract) revert();
        BasicNFTTokenMarket basicMarketContract = BasicNFTTokenMarket(_address);
        // Set the new contract address
        goodTokenMarket = basicMarketContract;
        hasMarketContract = true;
    }


    function lockMarketContractAddress() external onlyOwner {
        if(!hasMarketContract) revert();
        lockMarketContract = true;
    }

    //costs 20K gas to store a peice of data

		function registerNewGoodType( bytes32  goodTypeName,   uint256 totalSupply, uint256 claimPrice ) public
		{
      //if( (goodTypeName).length > 32) revert();
      uint256 typeId = uint256(keccak256( goodTypeName ));
      if(totalSupply < 1) revert();
			if(claimPrice < 0) revert();
			//make sure the goodtype doesnt exist

      //disallow timing attack
      if(goodTypes[typeId].initialized) revert();

      goodTypes[typeId] = GoodType({
         initialized:true,
         creator:msg.sender,
         typeId: typeId,
         name: goodTypeName,
         totalSupply: totalSupply,
         nextSupplyIndexToSell: 0,
         claimPrice: claimPrice,
         claimsEnabled: true,
         description: ""
        });


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

		function setClaimsPrice(uint256 claimPrice, uint256 typeId) public
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
      GoodType memory goodType = goodTypes[typeId];

        //prevent timing attack
      goodTypes[typeId].nextSupplyIndexToSell++;
			if(!goodType.initialized) revert(); //if the good isnt registered
			if(goodType.nextSupplyIndexToSell >= goodType.totalSupply) revert(); // the good is all claimed

      if (msg.value < goodType.claimPrice) revert();
      if (goodType.claimPrice < 0) revert();
      if (msg.value < 0) revert();
      if (goods.exists(typeId, goodType.nextSupplyIndexToSell)) revert();

      uint256 instanceId = goodType.nextSupplyIndexToSell;


      uint256 metadata = typeId;
	    goods.claimGoodToken(msg.sender,goods.buildTokenId(typeId,instanceId),metadata);

      //Content creator gets claim eth
      pendingWithdrawals[goodType.creator] += goodType.claimPrice;

      //refund overspends
      pendingWithdrawals[goodType.creator] += (msg.value - goodType.claimPrice);


			ClaimGood(msg.sender, typeId, goodType.nextSupplyIndexToSell );


		}




      function withdrawPendingBalance() public
      {

        uint256 amountToWithdraw = pendingWithdrawals[msg.sender];

        //prevent re-entrancy
        pendingWithdrawals[msg.sender] = 0;
        if( amountToWithdraw <= 0 ) revert();

        msg.sender.transfer( amountToWithdraw );

      }

}
