pragma solidity ^0.4.8;
contract EtherGoodsMarket {

    address owner;

    string public standard = 'EtherGoods';
    string public name;
    string public symbol;



		struct Good {
				bool initialized;
				address creator;
				string name;
				string description;
				uint totalSupply;
				//uint supplyRemaining;
				uint nextSupplyIndexToSell;
				uint256 uniqueHash; //The SHA3 hash of the artwork/asset. must be unique
				uint claimPrice;        // in ether
				bool claimsEnabled;


				//addresses of the people who own the good

				mapping (uint => address) supplyIndexToAddress;


				// A record of supplies that are offered for sale at a specific minimum value, and perhaps to a specific person
				mapping (uint => Offer) supplyOfferedForSale;

				// A record of the highest  bid
				mapping (uint => Bid) supplyBids;
		}

    struct Offer {
        bool isForSale;
				uint256 uniqueHash;
        uint supplyIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
				uint256 uniqueHash;
				uint supplyIndex;
        address bidder;
        uint value;
    }

	/*/	mapping (uint256 => address) public creatorAddress;*/

		//the uint256 is the unique hash of the good, SHA3
		mapping (uint256 => Good) public goods;






    mapping (address => uint) public pendingWithdrawals;

		event RegisterGood(address indexed to, uint256 goodHash);
		event RegistrationTransfer(address indexed from, address indexed to, uint256 goodHash);
		event ModifyClaimsEnable(address indexed owner,bool enabele,uint256 goodHash);
		event ModifyClaimsPrice(address indexed owner,uint price,uint256 goodHash);

    event ClaimGood(address indexed to, uint256 goodHash, uint supplyIndex);


  	event SupplyOffered(uint256 indexed uniqueHash, uint indexed supplyIndex, uint minValue, address indexed toAddress);
    event SupplyBidEntered(uint256 indexed uniqueHash, uint indexed supplyIndex, uint value, address indexed fromAddress);
    event SupplyBidWithdrawn(uint256 indexed uniqueHash, uint indexed supplyIndex, uint value, address indexed fromAddress);
		event SupplyBought(uint256 indexed uniqueHash, uint indexed supplyIndex, uint value, address fromAddress, address indexed toAddress);
		event SupplySold(uint256 indexed uniqueHash, uint indexed supplyIndex, uint value, address indexed fromAddress, address toAddress);
			//cant index enough !

  	event SupplyNoLongerForSale(uint256 indexed uniqueHash, uint indexed supplyIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthergoodsMarket() payable {
        owner = msg.sender;
           name = "ETHERGOODS";                                 // Set the name for display purposes
        symbol = "EGS";                     			          // Set the symbol for display purposes
     }


		function registerNewGood(address to, uint256 uniqueHash, string name, string description, uint totalSupply, uint claimPrice )
		{
			//make sure the good doesnt exist
			if(goods[uniqueHash].initialized) revert();
			if(totalSupply < 1) revert();
			if(claimPrice < 0) revert();

			goods[uniqueHash].initialized = true;
			goods[uniqueHash].creator = to; //usually msg.sender
			goods[uniqueHash].name = name;
			goods[uniqueHash].description = description;
			goods[uniqueHash].totalSupply = totalSupply;
			goods[uniqueHash].nextSupplyIndexToSell = 0;

			goods[uniqueHash].claimPrice = claimPrice; //initial price
			goods[uniqueHash].claimsEnabled = true;

			RegisterGood(to,uniqueHash);
		}


		//modifying existing goods registrations
		function setClaimsEnabled(bool enabled, uint256 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimsEnabled = enabled;

				ModifyClaimsEnable(msg.sender,enabled,uniqueHash);

		}

		function setClaimsPrice(uint claimPrice, uint256 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if(goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimPrice = claimPrice;

				ModifyClaimsPrice(msg.sender,claimPrice,uniqueHash);

		}

		function transferRegistration(address to, uint256 uniqueHash)
		{
				if(!goods[uniqueHash].initialized) revert();
				if(goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].creator = to;

				RegistrationTransfer(msg.sender,to,uniqueHash);

		}



		function claimGood(uint256 uniqueHash)
		{
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(goods[uniqueHash].nextSupplyIndexToSell >= goods[uniqueHash].totalSupply) revert(); //the the good is all sold out



			goods[uniqueHash].supplyIndexToAddress[goods[uniqueHash].nextSupplyIndexToSell] = msg.sender;

			ClaimGood(msg.sender, uniqueHash, goods[uniqueHash].nextSupplyIndexToSell );

			goods[uniqueHash].nextSupplyIndexToSell++;


		}





		function offerSupplyForSale(uint256 uniqueHash, uint supplyIndex, uint minSalePriceInWei) {
         if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
        if(goods[uniqueHash].supplyIndexToAddress[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
        if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

				goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(true, uniqueHash, supplyIndex, msg.sender, minSalePriceInWei, 0x0);
				SupplyOffered(uniqueHash,supplyIndex, minSalePriceInWei, 0x0);
    }

		function offerSupplyForSaleToAddress(uint256 uniqueHash, uint supplyIndex, uint minSalePriceInWei, address toAddress) {
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(goods[uniqueHash].supplyIndexToAddress[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
			if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

				goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(true, uniqueHash, supplyIndex, msg.sender, minSalePriceInWei, toAddress);

        	SupplyOffered(uniqueHash,supplyIndex, minSalePriceInWei, toAddress);
    }


    function supplyNoLongerForSale(uint256 uniqueHash, uint supplyIndex) {
			if(!goods[uniqueHash].initialized) revert(); //if the good isnt registered
			if(goods[uniqueHash].supplyIndexToAddress[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
			if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

        goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(false, uniqueHash, supplyIndex, msg.sender, 0, 0x0);
        SupplyNoLongerForSale(uniqueHash,supplyIndex);
    }









    function buySupply(uint256 uniqueHash, uint supplyIndex) payable {
    		if(!goods[uniqueHash].initialized) revert();
        Offer offer = goods[uniqueHash].supplyOfferedForSale[supplyIndex];
        if(supplyIndex >= goods[uniqueHash].totalSupply) revert();
        if (!offer.isForSale) revert();                // supply not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  //  not supposed to be sold to this user
        if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
        if (offer.seller != goods[uniqueHash].creator) revert(); // Seller no longer owner of

        address seller = offer.seller;

				goods[uniqueHash].supplyIndexToAddress[supplyIndex] = msg.sender; //set the new owner of the supply
      //  balanceOf[seller]--;
    	// balanceOf[msg.sender]++;
      //  TransferSupply(seller, msg.sender, 1);

        SupplyNoLongerForSale(uniqueHash,supplyIndex);
        pendingWithdrawals[seller] += msg.value;
				SupplyBought(uniqueHash,supplyIndex, msg.value, seller, msg.sender);
				SupplySold(uniqueHash,supplyIndex, msg.value, seller, msg.sender);


					//FIX MEE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = goods[uniqueHash].supplyBids[supplyIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            goods[uniqueHash].supplyBids[supplyIndex] = Bid(false, uniqueHash, supplyIndex, 0x0, 0);
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

    function enterBidForSupply(uint256 uniqueHash, uint supplyIndex) payable {


			if(!goods[uniqueHash].initialized) revert();
			if(supplyIndex >= goods[uniqueHash].totalSupply) revert();


        if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == 0x0) revert();
        if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == msg.sender) revert();
        if (msg.value == 0) revert();
				Bid existing = goods[uniqueHash].supplyBids[supplyIndex];

        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        goods[uniqueHash].supplyBids[supplyIndex] = Bid(true, uniqueHash, supplyIndex, msg.sender, msg.value);
        SupplyBidEntered(uniqueHash, supplyIndex, msg.value, msg.sender);
    }

    function acceptBidForSupply(uint256 uniqueHash, uint supplyIndex, uint minPrice) {

				if(!goods[uniqueHash].initialized) revert();
				if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

				if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == msg.sender) revert();
        address seller = msg.sender;
        Bid bid = goods[uniqueHash].supplyBids[supplyIndex];
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        goods[uniqueHash].supplyIndexToAddress[supplyIndex] = bid.bidder;
        //balanceOf[seller]--;
        //balanceOf[bid.bidder]++;
        //Transfer(seller, bid.bidder, 1);

        goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(false, uniqueHash, supplyIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        goods[uniqueHash].supplyBids[supplyIndex] = Bid(false, uniqueHash, supplyIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        SupplyBought(uniqueHash, supplyIndex, bid.value, seller, bid.bidder);
				SupplySold(uniqueHash, supplyIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForSupply(uint256 uniqueHash, uint supplyIndex) {
				if(!goods[uniqueHash].initialized) revert();
				if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

			   if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == 0x0) revert();
				if (goods[uniqueHash].supplyIndexToAddress[supplyIndex] == msg.sender) revert();
			  Bid bid = goods[uniqueHash].supplyBids[supplyIndex];
			  if (bid.bidder != msg.sender) revert();
        SupplyBidWithdrawn(uniqueHash,supplyIndex, bid.value, msg.sender);
        uint amount = bid.value;
        goods[uniqueHash].supplyBids[supplyIndex] = Bid(false, uniqueHash, supplyIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}
