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


    mapping (uint256 => address) public creatorAddress;


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
				uint minPrice;        // in ether
				//uint public nextPunkIndexToAssign = 0;
				//bool public allPunksAssigned = false;
				//bool allInstancesSold = false;

				//addresses of the people who own the good
				mapping (address => uint) addressToSupplyIndex;

		}

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint value;
    }

		mapping (string => Good) public goods;


    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping (uint => Bid) public punkBids;

    mapping (address => uint) public pendingWithdrawals;

		event RegisterGood(address indexed to, uint256 goodHash);
    event PurchaseGood(address indexed to, uint256 goodHash, uint supplyIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
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
			goods[uniqueHash].minPrice = minPrice;

			Register(to,uniqueHash);
		}


		function purchaseGood(uint256 uniqueHash)
		{
			if(goods[uniqueHash] == 0x0) revert(); //if the good isnt registered
			if(goods[uniqueHash].nextSupplyIndexToSell == goods[uniqueHash].totalSupply) revert(); //the the good is all sold out


			PurchaseGood(msg.sender, uniqueHash, goods[uniqueHash].nextSupplyIndexToSell );

			goods[uniqueHash].addressToSupplyIndex[msg.sender] = goods[uniqueHash].nextSupplyIndexToSell;
			goods[uniqueHash].nextSupplyIndexToSell++;


		}


/*
    function setInitialOwner(address to, uint punkIndex) {
        if (msg.sender != owner) revert();
        if (allPunksAssigned) revert();
        if (punkIndex >= 10000) revert();
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != 0x0) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            Assign(to, punkIndex);
        }
    }
		*/

  /*  function setInitialOwners(address[] addresses, uint[] indices) {
        if (msg.sender != owner) revert();
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() {
        if (msg.sender != owner) revert();
        allPunksAssigned = true;
    }*/



    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, 0x0, 0);
        }
    }

    function punkNoLongerForSale(uint punkIndex) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, 0x0);
        PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, 0x0);
        PunkOffered(punkIndex, minSalePriceInWei, 0x0);
    }

    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= 10000) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint punkIndex) payable {
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
