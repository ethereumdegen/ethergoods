pragma solidity ^0.4.15;

import './Ownable.sol';
import './BasicNFT.sol';

contract BasicNFTTokenMarket is Ownable  {

  address owner;
  BasicNFT public tokenContract;
  uint256 public ownerCut;

  bool hasTokenContract = false;

  mapping (address => uint) public pendingWithdrawals;

  event TransferSupply(uint256 indexed typeId,address indexed from, address indexed to, uint amount);

  event SupplyOffered(uint256 indexed typeId, uint minValue, address indexed toAddress);
  event SupplyBidEntered(uint256 indexed typeId, uint value, address indexed fromAddress);
  event SupplyBidWithdrawn(uint256 indexed typeId, uint value, address indexed fromAddress);
  event SupplyBought(uint256 indexed typeId,  uint value, address fromAddress, address indexed toAddress);
  event SupplySold(uint256 indexed typeId, uint value, address indexed fromAddress, address toAddress);

  event SupplyNoLongerForSale(uint256 indexed typeId);
//  event BidNoLongeOffered(uint256 indexed typeId);



  function BasicNFTTokenMarket(address _nftAddress, uint256 _cut) public onlyOwner {
      require(_cut <= 10000);
      ownerCut = _cut;

      BasicNFT basicNFTContract = BasicNFT(_nftAddress);
      //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
      tokenContract = basicNFTContract;
      hasTokenContract = true;
  }

  function setTokenContractAddress(address _address) external onlyOwner {
      BasicNFT basicNFTContract = BasicNFT(_address);

      // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
      //require(candidateContract.isSaleClockAuction());

      // Set the new contract address
      tokenContract = basicNFTContract;
      hasTokenContract = true;
  }

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
      uint256 tokenId;
    //  uint16 supplyIndex;
      address seller;
      uint256 minValue;          // in ether
      address onlySellTo;     // specify to sell only to a specific person
  }

  struct Bid {
      bool hasBid;
      uint256 tokenId;
      //uint16 supplyIndex;
      address bidder;
      uint256 value;
  }


  mapping(address => Bid[]) public bids;

  // A record of supplies that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping (uint256 => Offer) public supplyOfferedForSale;

  // A record of the highest  bid
  mapping (uint256 => Bid) public supplyBids;




  function tokenContractExists() public returns (bool){
    return hasTokenContract;
  }


  //tokenId is the keccak of the typeId and instanceId
  function tokenExists(uint tokenId) public constant returns (bool) {
     return tokenContract.tokenOwner(tokenId) != 0x0;
   }

  function offerSupplyForSale(uint256 tokenId, uint minSalePriceInWei) public {
      if(!tokenExists(tokenId)) revert(); //if the good isnt registered
      if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

    /*  if(supplyOfferedForSale[uniqueHash].isForSale)
      {
        if(minSalePriceInWei > supplyOfferedForSale[uniqueHash].minValue) revert();
      }*/

      supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, 0x0);
      SupplyOffered(tokenId, minSalePriceInWei, 0x0);
  }

  function offerSupplyForSaleToAddress(uint256 tokenId, uint minSalePriceInWei, address toAddress) public {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert(); //must have balance of the token

    supplyOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, toAddress);
    SupplyOffered(tokenId, minSalePriceInWei, toAddress);

  }


  function supplyNoLongerForSale(uint256 tokenId) public {
    if(!tokenExists(tokenId)) revert(); //if the good isnt registered
    if(tokenContract.ownerOf(tokenId) != msg.sender ) revert();
    if(supplyOfferedForSale[tokenId].seller != msg.sender) revert(); //must be the owner of this supply


     supplyOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, 0x0);
     SupplyNoLongerForSale(tokenId);
  }




  function buySupply(uint256 tokenId) public payable {
      if(!tokenExists(tokenId)) revert();
      Offer memory offer = supplyOfferedForSale[tokenId];
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

      uint256 market_fee = msg.value/50;

      pendingWithdrawals[owner] += market_fee;

      pendingWithdrawals[seller] += (msg.value - market_fee);

      SupplyBought(tokenId, msg.value, seller, msg.sender);
      SupplySold(tokenId, msg.value, seller, msg.sender);

      // Check for the case where there is a bid from the new owner and refund it.
      // Any other bid can stay in place.
      Bid memory bid =  supplyBids[tokenId];
      if (bid.bidder == msg.sender) {
          // Kill bid and refund value
          pendingWithdrawals[msg.sender] += bid.value;
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      }
  }



  function enterBidForSupply(uint256 tokenId) public payable {
    if(!tokenExists(tokenId)) revert();

      if (msg.value == 0) revert();
      Bid memory existing =  supplyBids[tokenId];
      if (msg.value <= existing.value) revert(); //need to bid higher
      if (existing.value > 0 && existing.hasBid) {  ///if there is another active bid
          // Refund the failing bid
          pendingWithdrawals[existing.bidder] += existing.value;
          supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      }

       supplyBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
       SupplyBidEntered(tokenId, msg.value, msg.sender);
  }

  function acceptBidForSupply(uint256 tokenId, uint minPrice) public {

      if(!tokenExists(tokenId)) revert();

       address seller = msg.sender;
       Bid memory bid = supplyBids[tokenId];
      if(bid.bidder == msg.sender) revert(); //cant accept own bid

      if(tokenContract.ownerOf(tokenId) != seller ) revert(); //must have balance of the token

      if (bid.value == 0) revert();
      if (bid.value < minPrice) revert();

      tokenContract.transfer(msg.sender,tokenId);
      TransferSupply(tokenId,seller, bid.bidder, 1);

      supplyOfferedForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, 0x0);
      uint256 amount = bid.value;
      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);

      uint256 market_fee = amount/50;

      pendingWithdrawals[owner] += market_fee;
      pendingWithdrawals[seller] += (amount - market_fee);

      SupplyBought(tokenId, bid.value, seller, bid.bidder);
      SupplySold(tokenId, bid.value, seller, bid.bidder);
  }

  function withdrawBidForSupply(uint256 tokenId) public {
      if(!tokenExists(tokenId)) revert();

      Bid memory bid = supplyBids[tokenId];
      if (bid.bidder != msg.sender) revert();

      SupplyBidWithdrawn(tokenId, bid.value, msg.sender);

      supplyBids[tokenId] = Bid(false, tokenId, 0x0, 0);
      // Refund the bid money

      pendingWithdrawals[msg.sender] +=  bid.value;
  }


  function withdrawPendingBalance() public
  {
    if( pendingWithdrawals[msg.sender] <= 0 ) revert();

    msg.sender.transfer( pendingWithdrawals[msg.sender] );

    pendingWithdrawals[msg.sender] = 0;
  }




}
