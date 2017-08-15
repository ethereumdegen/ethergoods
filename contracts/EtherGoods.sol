pragma solidity ^0.4.8;
contract EtherGoods {

    address owner;

    string public standard = 'EtherGoods';
    string public name;
    string public version;



		struct Good {
				bool initialized;
				address creator;
				string name;
				string description;
				uint16 totalSupply;   //max is 2^16
				//uint supplyRemaining;
				uint16 nextSupplyIndexToSell;
				bytes32 uniqueHash; //The SHA3 hash of the artwork/asset. must be unique
				uint claimPrice;        // in wei
				bool claimsEnabled;


				//addresses of the people who own the good


        mapping (address => uint32) balanceOf;  //supply owned by this address



        //consider removing this !
    //    mapping (uint16 => address) supplyIndexToAddress;


		}

    // A record of supplies that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (bytes32 => Offer) public supplyOfferedForSale;

    // A record of the highest  bid
    mapping (bytes32 => Bid) public supplyBids;

    struct Offer {
        bool isForSale;
				bytes32 uniqueHash;
      //  uint16 supplyIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
				bytes32 uniqueHash;
				//uint16 supplyIndex;
        address bidder;
        uint value;
    }

	/*/	mapping (uint256 => address) public creatorAddress;*/

		//the uint256 is the unique hash of the good, SHA3
		mapping (bytes32 => Good) public goods;






    mapping (address => uint) public pendingWithdrawals;

		event RegisterGood(address indexed to, bytes32 goodHash);
		event RegistrationTransfer(address indexed from, address indexed to, bytes32 goodHash);
		event ModifyClaimsEnable(address indexed owner,bool enabele,bytes32 goodHash);
    event ModifyClaimsPrice(address indexed owner,uint price,bytes32 goodHash);
    event ModifyGoodDescription(address indexed owner,string description,bytes32 goodHash);


    event ClaimGood(address indexed to, bytes32 goodHash, uint32 supplyIndex);
    event TransferSupply(bytes32 indexed uniqueHash,address indexed from, address indexed to, uint amount);

  	event SupplyOffered(bytes32 indexed uniqueHash, uint minValue, address indexed toAddress);
    event SupplyBidEntered(bytes32 indexed uniqueHash, uint value, address indexed fromAddress);
    event SupplyBidWithdrawn(bytes32 indexed uniqueHash, uint value, address indexed fromAddress);
		event SupplyBought(bytes32 indexed uniqueHash,  uint value, address fromAddress, address indexed toAddress);
		event SupplySold(bytes32 indexed uniqueHash, uint value, address indexed fromAddress, address toAddress);
			//cant index enough !

  	event SupplyNoLongerForSale(bytes32 indexed uniqueHash);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthergoodsMarket() payable {
        owner = msg.sender;
        name = "ETHERGOODS";                                 // Set the name for display purposes
        version = "0.2.1";
    }


		function registerNewGood( bytes32 uniqueHash, string name, uint16 totalSupply, uint claimPrice )
		{
			//make sure the good doesnt exist
			if(goods[uniqueHash].initialized) revert();
			if(totalSupply < 1) revert();
			if(claimPrice < 0) revert();

			goods[uniqueHash].initialized = true;
			goods[uniqueHash].creator = msg.sender; //usually msg.sender
			goods[uniqueHash].name = name;
			//goods[uniqueHash].description = description;
			goods[uniqueHash].totalSupply = totalSupply;
			goods[uniqueHash].nextSupplyIndexToSell = 0;
      goods[uniqueHash].uniqueHash = uniqueHash;

			goods[uniqueHash].claimPrice = claimPrice; //initial price
			goods[uniqueHash].claimsEnabled = true;

			RegisterGood(msg.sender,uniqueHash);
		}




    function setGoodDescription(string description, bytes32 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].description = description;

				ModifyGoodDescription(msg.sender,description,uniqueHash);

		}

		//modifying existing goods registrations
		function setClaimsEnabled(bool enabled, bytes32 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimsEnabled = enabled;

				ModifyClaimsEnable(msg.sender,enabled,uniqueHash);

		}

		function setClaimsPrice(uint claimPrice, bytes32 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if(goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimPrice = claimPrice;

				ModifyClaimsPrice(msg.sender,claimPrice,uniqueHash);

		}

		function transferRegistration(address to, bytes32 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if(goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].creator = to;

				RegistrationTransfer(msg.sender,to,uniqueHash);

		}



		function claimGood(bytes32 uniqueHash) payable
		{
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(goods[uniqueHash].nextSupplyIndexToSell >= goods[uniqueHash].totalSupply) revert(); // the good is all claimed
      if (msg.value == 0) revert();
      if (msg.value < goods[uniqueHash].claimPrice) revert();


		//	goods[uniqueHash].supplyIndexToAddress[goods[uniqueHash].nextSupplyIndexToSell] = msg.sender;

      goods[uniqueHash].balanceOf[msg.sender]++;

			ClaimGood(msg.sender, uniqueHash, goods[uniqueHash].nextSupplyIndexToSell );

			goods[uniqueHash].nextSupplyIndexToSell++;


		}

    //amount of supply that an account owns
    function getSupplyBalance(bytes32 uniqueHash, address to) returns (uint amount)
    {
      if(!goods[uniqueHash].initialized) revert();
      amount = goods[uniqueHash].balanceOf[to];
    }

    //the account that owns a particular supply
  //  function getSupplyIndexToAddress(bytes32 uniqueHash, uint16 supplyIndex) returns (address to)
  //  {
  //    if(!goods[uniqueHash].initialized) revert();
  //    to = goods[uniqueHash].supplyIndexToAddress[supplyIndex];
  //  }









		function offerSupplyForSale(bytes32 uniqueHash, uint minSalePriceInWei) {
         if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered

        if(goods[uniqueHash].balanceOf[msg.sender] < 1) revert(); //must have balance of the token
        if(supplyOfferedForSale[uniqueHash].isForSale)
        {
          if(minSalePriceInWei > supplyOfferedForSale[uniqueHash].minValue) revert();
        }

				supplyOfferedForSale[uniqueHash] = Offer(true, uniqueHash, msg.sender, minSalePriceInWei, 0x0);
				SupplyOffered(uniqueHash, minSalePriceInWei, 0x0);
    }

		function offerSupplyForSaleToAddress(bytes32 uniqueHash, uint minSalePriceInWei, address toAddress) {
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(goods[uniqueHash].balanceOf[msg.sender] < 1) revert();


				supplyOfferedForSale[uniqueHash] = Offer(true, uniqueHash, msg.sender, minSalePriceInWei, toAddress);

        	SupplyOffered(uniqueHash, minSalePriceInWei, toAddress);
    }


    function supplyNoLongerForSale(bytes32 uniqueHash) {
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(supplyOfferedForSale[uniqueHash].seller != msg.sender) revert(); //must be the owner of this supply


        supplyOfferedForSale[uniqueHash] = Offer(false, uniqueHash, msg.sender, 0, 0x0);
        SupplyNoLongerForSale(uniqueHash);
    }




    function buySupply(bytes32 uniqueHash) payable {
    		if(!goods[uniqueHash].initialized) revert();
        Offer offer = supplyOfferedForSale[uniqueHash];
      //  if(supplyIndex >= goods[uniqueHash].totalSupply) revert();
        if (!offer.isForSale) revert();                // supply not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  //  not supposed to be sold to this user
        if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
    //    if (offer.seller != goods[uniqueHash].creator) revert(); // Seller no longer owner of

        address seller = offer.seller;

				//goods[uniqueHash].supplyIndexToAddress[supplyIndex] = msg.sender; //set the new owner of the supply
        goods[uniqueHash].balanceOf[seller]--;
      	goods[uniqueHash].balanceOf[msg.sender]++;
        TransferSupply(uniqueHash, seller, msg.sender, 1);

        SupplyNoLongerForSale(uniqueHash);
        pendingWithdrawals[seller] += msg.value;
				SupplyBought(uniqueHash, msg.value, seller, msg.sender);
				SupplySold(uniqueHash, msg.value, seller, msg.sender);


        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid =  supplyBids[uniqueHash];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
             supplyBids[uniqueHash] = Bid(false, uniqueHash, 0x0, 0);
        }
    }


		//this does not have to change
    function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForSupply(bytes32 uniqueHash) payable {


			if(!goods[uniqueHash].initialized) revert();
			//if(supplyIndex >= goods[uniqueHash].totalSupply) revert();


        if (msg.value == 0) revert();
				Bid existing =  supplyBids[uniqueHash];

        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }

         supplyBids[uniqueHash] = Bid(true, uniqueHash, msg.sender, msg.value);
        SupplyBidEntered(uniqueHash, msg.value, msg.sender);
    }

    function acceptBidForSupply(bytes32 uniqueHash, uint minPrice) {

				if(!goods[uniqueHash].initialized) revert();

        address seller = msg.sender;
        Bid bid = supplyBids[uniqueHash];
        if(bid.bidder == msg.sender) revert(); //cant accept own bid
        if (goods[uniqueHash].balanceOf[seller] < 1 ) revert();
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        //goods[uniqueHash].supplyIndexToAddress[supplyIndex] = bid.bidder;
        goods[uniqueHash].balanceOf[seller]--;
        goods[uniqueHash].balanceOf[bid.bidder]++;
        TransferSupply(uniqueHash,seller, bid.bidder, 1);

        supplyOfferedForSale[uniqueHash] = Offer(false, uniqueHash, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        supplyBids[uniqueHash] = Bid(false, uniqueHash, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        SupplyBought(uniqueHash, bid.value, seller, bid.bidder);
				SupplySold(uniqueHash, bid.value, seller, bid.bidder);
    }

    function withdrawBidForSupply(bytes32 uniqueHash) {
				if(!goods[uniqueHash].initialized) revert();
				//if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

			  //if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == 0x0) revert();
				//if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == msg.sender) revert();
			  Bid bid = supplyBids[uniqueHash];
			  if (bid.bidder != msg.sender) revert();
        SupplyBidWithdrawn(uniqueHash, bid.value, msg.sender);
        uint amount = bid.value;
         supplyBids[uniqueHash] = Bid(false, uniqueHash, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}
