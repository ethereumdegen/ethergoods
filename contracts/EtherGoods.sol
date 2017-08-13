pragma solidity ^0.4.8;
contract EtherGoodsMarket {

    // You can use this hash to verify the image file containing all the punks
  //  string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'EtherGoods';
    string public name;
    string public symbol;
    //uint8 public decimals;
    //uint256 public totalSupply;

    //mapping (address => uint) public addressToPunkIndex;




    /* This creates an array with all balances */
  //  mapping (address => uint256) public balanceOf;

		struct Good {
				address creator;
				string name;
				string description;
				uint totalSupply;
				//uint supplyRemaining;
				uint nextSupplyIndexToSell;
				uint256 uniqueHash; //The SHA3 hash of the artwork/asset. must be unique
				uint claimPrice;        // in ether
				bool claimsEnabled;

				//uint public nextPunkIndexToAssign = 0;
				//bool public allPunksAssigned = false;
				//bool allInstancesSold = false;

				//addresses of the people who own the good
				mapping (address => uint) addressToSupplyIndex;

				// A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
				mapping (uint => Offer) supplyOfferedForSale;

				// A record of the highest punk bid
				mapping (uint => Bid) supplyBids;
		}

    struct Offer {
        bool isForSale;
				uint256 uniqueHash
        uint supplyIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
				uint256 uniqueHash
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

    event PurchaseGood(address indexed to, uint256 goodHash, uint supplyIndex);

  	event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EthergoodsMarket() payable {
        owner = msg.sender;
        //totalSupply = 10000;                        // Update total supply
        //punksRemainingToAssign = totalSupply;
        name = "ETHERGOODS";                                 // Set the name for display purposes
        symbol = "EGS";                     			          // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }


		function registerNewGood(address to, uint256 uniqueHash, string name, string description, uint totalSupply, uint minPrice )
		{
			//make sure the good doesnt exist
			if(goods[uniqueHash] != 0x0) revert();
			if(totalSupply < 1) revert();
			if(minPrice < 0) revert();

			goods[uniqueHash].creator = to; //usually msg.sender
			goods[uniqueHash].name = name;
			goods[uniqueHash].description = description;
			goods[uniqueHash].totalSupply = totalSupply;
			goods[uniqueHash].nextSupplyIndexToSell = 0;

			goods[uniqueHash].claimPrice = claimPrice; //initial price
			goods[uniqueHash].claimsEnabled = true;

			Register(to,uniqueHash);
		}


		//modifying existing goods registrations
		function setClaimsEnabled(bool enabled, uint256 uniqueHash)
		{
				if(goods[uniqueHash] != 0x0) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimsEnabled = enabled;

				ModifyClaimsEnable(msg.sender,enabled,uniqueHash);

		}

		function setClaimsPrice(unit claimPrice, uint256 uniqueHash)
		{
				if(goods[uniqueHash] != 0x0) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].claimPrice = claimPrice;

				ModifyClaimsPrice(msg.sender,claimPrice,uniqueHash);

		}

		function transferRegistration(address to, uint256 uniqueHash)
		{
				if(goods[uniqueHash] != 0x0) revert();
				if (goods[uniqueHash].creator != msg.sender) revert(); //must own the registration to transfer it

				goods[uniqueHash].creator = to;

				RegistrationTransfer(msg.sender,to,uniqueHash);

		}



		function purchaseGood(uint256 uniqueHash)
		{
			if(goods[uniqueHash] == 0x0) revert(); //if the good isnt registered
			if(goods[uniqueHash].nextSupplyIndexToSell >= goods[uniqueHash].totalSupply) revert(); //the the good is all sold out


			PurchaseGood(msg.sender, uniqueHash, goods[uniqueHash].nextSupplyIndexToSell );

			goods[uniqueHash].addressToSupplyIndex[msg.sender] = goods[uniqueHash].nextSupplyIndexToSell;
			goods[uniqueHash].nextSupplyIndexToSell++;


		}





		function offerSupplyForSale(uint256 uniqueHash, uint supplyIndex, uint minSalePriceInWei) {
        //if (!allPunksAssigned) revert();
				if(goods[uniqueHash] == 0x0) revert(); //if the good isnt registered
        if(goods[uniqueHash].addressToSupplyIndex[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
        if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

				goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(true, uniqueHash, supplyIndex, msg.sender, minSalePriceInWei, 0x0);
			  //punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, 0x0);
        //PunkOffered(punkIndex, minSalePriceInWei, 0x0);
				SupplyOffered(uniqueHash,supplyIndex, minSalePriceInWei, 0x0);
    }

		function offerSupplyForSaleToAddress(uint256 uniqueHash, uint supplyIndex, uint minSalePriceInWei, address toAddress) {
			if(goods[uniqueHash] == 0x0) revert(); //if the good isnt registered
			if(goods[uniqueHash].addressToSupplyIndex[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
			if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

				goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(true, uniqueHash, supplyIndex, msg.sender, minSalePriceInWei, toAddress);

        	SupplyOffered(uniqueHash,supplyIndex, minSalePriceInWei, toAddress);
    }


    function supplyNoLongerForSale(uint256 uniqueHash, uint supplyIndex) {
			if(goods[uniqueHash] == 0x0) revert(); //if the good isnt registered
			if(goods[uniqueHash].addressToSupplyIndex[supplyIndex] != msg.sender) revert(); //must be the owner of this supply
			if(supplyIndex >= goods[uniqueHash].totalSupply) revert();

        goods[uniqueHash].supplyOfferedForSale[supplyIndex] = Offer(false, uniqueHash, supplyIndex, msg.sender, 0, 0x0);
        SupplyNoLongerForSale(uniqueHash,supplyIndex);
    }









    function buySupply(uint punkIndex) payable {
        if (!allPunksAssigned) revert();
        Offer offer = punksOfferedForSale[punkIndex];
        if (punkIndex >= 10000) revert();
        if (!offer.isForSale) revert();                // punk not actually for sale
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
        if (offer.seller != punkIndexToAddress[punkIndex]) revert(); // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        }
    }

    function withdraw() {
        if (!allPunksAssigned) revert();
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint punkIndex) payable {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] == 0x0) revert();
        if (punkIndexToAddress[punkIndex] == msg.sender) revert();
        if (msg.value == 0) revert();
        Bid existing = punkBids[punkIndex];
        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint punkIndex, uint minPrice) {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        address seller = msg.sender;
        Bid bid = punkBids[punkIndex];
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint punkIndex) {
        if (punkIndex >= 10000) revert();
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] == 0x0) revert();
        if (punkIndexToAddress[punkIndex] == msg.sender) revert();
        Bid bid = punkBids[punkIndex];
        if (bid.bidder != msg.sender) revert();
        PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}
