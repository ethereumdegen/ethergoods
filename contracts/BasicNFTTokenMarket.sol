pragma solidity ^0.4.15;

import './BasicNFT.sol';

contract BasicNFTTokenMarket   {

  address contractOwner;
  BasicNFT public tokenContract;

  // Array of owned tokens for a user
/*  mapping(address => uint[]) public ownedTokens;
  mapping(address => uint) _virtualLength;
  mapping(uint => uint) _tokenIndexInOwnerArray;

  // Mapping from token ID to owner
  mapping(uint => address) public tokenOwner;

  // Allowed transfers for a token (only one at a time)
  mapping(uint => address) public allowedTransfer;

  // Metadata associated with each token
  mapping(uint => string) public _tokenMetadata;*/

  struct Offer {
      bool isForSale;
      bytes32 tokenId;
    //  uint16 supplyIndex;
      address seller;
      uint minValue;          // in ether
      address onlySellTo;     // specify to sell only to a specific person
  }

  struct Bid {
      bool hasBid;
      bytes32 tokenId;
      //uint16 supplyIndex;
      address bidder;
      uint value;
  }


  mapping(address => Bid[]) public bids;

  // A record of supplies that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping (bytes32 => Offer) public supplyOfferedForSale;

  // A record of the highest  bid
  mapping (bytes32 => Bid) public supplyBids;




  function setTokenContract(contract) onlyOwner public{
    tokenContract = contract;
  }

  function hasTokenContract() public{
    return tokenContract != 0x0;
  }


  //tokenId is the keccak of the typeId and instanceId
  function tokenExists(uint tokenId) public constant returns (bool) {
     return tokenContract.tokenOwner[tokenId] != 0x0;
   }

  function offerSupplyForSale(bytes32 tokenId, uint minSalePriceInWei) {
      if(!tokenExists(tokenId)) revert(); //if the good isnt registered
      if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

    /*  if(supplyOfferedForSale[uniqueHash].isForSale)
      {
        if(minSalePriceInWei > supplyOfferedForSale[uniqueHash].minValue) revert();
      }*/

      supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, 0x0);
      SupplyOffered(tokenId, minSalePriceInWei, 0x0);
  }

  function offerSupplyForSaleToAddress(bytes32 tokenId, uint minSalePriceInWei, address toAddress) {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

    supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, toAddress);
    SupplyOffered(tokenId, minSalePriceInWei, toAddress);

  }


  function supplyNoLongerForSale(bytes32 tokenId) {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert();
    if(supplyOfferedForSale[tokenId].seller != msg.sender) revert(); //must be the owner of this supply


     supplyOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, 0x0);
     SupplyNoLongerForSale(tokenId);
  }




  function buySupply(bytes32 tokenId) payable {
      if(!tokenExists(tokenId)) revert();
      Offer offer = supplyOfferedForSale[tokenId];
    //  if(supplyIndex >= goods[uniqueHash].totalSupply) revert();
      if (!offer.isForSale) revert();                // supply not actually for sale
      if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) revert();  //  not supposed to be sold to this user
      if (msg.value < offer.minValue) revert();      // Didn't send enough ETH
      if (offer.minValue < 0) revert();
      if (msg.value < 0) revert();

  //    if (offer.seller != goods[uniqueHash].creator) revert(); // Seller no longer owner of

      address seller = offer.seller;


      tokenContract.transfer(msg.sender,tokenId);
      TransferSupply(tokenId, seller, msg.sender, 1);
      SupplyNoLongerForSale(tokenId);

      uint market_fee = msg.value/50;

      pendingWithdrawals[contractOwner] += market_fee;

      pendingWithdrawals[seller] += (msg.value - market_fee);

      SupplyBought(tokenId, msg.value, seller, msg.sender);
      SupplySold(tokenId, msg.value, seller, msg.sender);

      // Check for the case where there is a bid from the new owner and refund it.
      // Any other bid can stay in place.
      Bid bid =  supplyBids[tokenId];
      if (bid.bidder == msg.sender) {
          // Kill bid and refund value
          pendingWithdrawals[msg.sender] += bid.value;
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      }
  }



  function enterBidForSupply(bytes32 tokenId) payable {
    if(!tokenExists(tokenId)) revert();

      if (msg.value == 0) revert();
      Bid existing =  supplyBids[tokenId];
      if (msg.value <= existing.value) revert(); //need to bid higher
      if (existing.value > 0 && existing.hasBid) {  ///if there is another active bid
          // Refund the failing bid
          pendingWithdrawals[existing.bidder] += existing.value;
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      }

       supplyBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
       SupplyBidEntered(tokenId, msg.value, msg.sender);
  }

  function acceptBidForSupply(bytes32 tokenId, uint minPrice) {

      if(!tokenExists(tokenId)) revert();

      address seller = msg.sender;
      Bid bid = supplyBids[tokenId];
      if(bid.bidder == msg.sender) revert(); //cant accept own bid

      if(tokenContract.ownerOf(tokenId) != seller ) revert(); //must have balance of the token

      if (bid.value == 0) revert();
      if (bid.value < minPrice) revert();

      tokenContract.transfer(msg.sender,tokenId);
      TransferSupply(uniquetokenIdHash,seller, bid.bidder, 1);

      supplyOfferedForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, 0x0);
      uint amount = bid.value;
      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);

      uint market_fee = amount/50;

      pendingWithdrawals[owner] += market_fee;
      pendingWithdrawals[seller] += (amount - market_fee);

      SupplyBought(tokenId, bid.value, seller, bid.bidder);
      SupplySold(tokenId, bid.value, seller, bid.bidder);
  }

  function withdrawBidForSupply(bytes32 tokenId) {
      if(!tokenExists(tokenId)) revert();

      Bid bid = supplyBids[tokenId];
      if (bid.bidder != msg.sender) revert();
      SupplyBidWithdrawn(tokenId, bid.value, msg.sender);
      uint amount = bid.value;
      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      // Refund the bid money

      pendingWithdrawals[msg.sender] += market_fee;
  }


  function withdrawPendingBalance()
  {
    if( pendingWithdrawals[msg.sender] <= 0 ) revert();

    msg.sender.transfer( pendingWithdrawals[msg.sender] );

    pendingWithdrawals[msg.sender] = 0;
  }




}
