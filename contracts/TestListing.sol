import './GOODTYPEToken.sol';

contract GOODTYPETestListing is GOODTYPEToken {

  function GOODTYPETestListing() public {
    owner = this;
  }

  /*function buy(uint256 _x, uint256 _y, string _data) public {
    uint token = buildTokenId(_x, _y);
    if (ownerOf(token) != 0) {
      _transfer(ownerOf(token), msg.sender, token);
      _tokenMetadata[token] = _data;
    } else {
      _assignNewParcel(msg.sender, token, _data);
    }
  }*/

  function list(uint256 _x, uint256 _y, string _data) public {
    uint token = buildTokenId(_x, _y);
    if (ownerOf(token) != 0) {
      _transfer(ownerOf(token), msg.sender, token);
      _tokenMetadata[token] = _data;
    } else {
      _assignNewParcel(msg.sender, token, _data);
    }
  }

}
