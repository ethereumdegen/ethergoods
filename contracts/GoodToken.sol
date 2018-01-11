pragma solidity ^0.4.8;
import './Ownable.sol';
import './BasicNFT.sol';

// SEE https://github.com/decentraland/land/tree/master/contracts

contract GoodToken is Ownable, BasicNFT {

    bool public isGoodToken = true;

    address owner;

    address masterContract;

    bool initialized;

    string public name = 'Ethergoods Asset';
    string public symbol = 'GOOD';

    //  bytes32 uniqueHash; //the id of the asset instance
    //  bytes32 typeCreationHash;

    //similar to LAND but X is the goodType and Y is the instanceId of the token

    function setMasterContractAddress(address _address) external onlyOwner {
        masterContract = _address;
    }

    function claimGoodToken(address beneficiary, uint tokenId, uint256 _metadata) public {
        if(msg.sender != masterContract) revert()
        require(tokenOwner[tokenId] == 0);
       _claimNewToken(beneficiary, tokenId, _metadata);
     }

     function _claimNewToken(address beneficiary, uint tokenId, uint256 _metadata) internal {
        //latestPing[tokenId] = now;
        _addTokenTo(beneficiary, tokenId);
        totalTokens++;
        _tokenMetadata[tokenId] = _metadata;

        Created(tokenId, beneficiary, _metadata);
      }

      //this returns the GoodTypeId since that is what the metadata is
    function goodMetadata(uint typeId, uint instanceId) constant public returns (uint256) {
        return _tokenMetadata[buildTokenId(typeId,instanceId)];
    }

    function exists(uint typeId, uint instanceId) public constant returns (bool) {
       return ownerOfToken(typeId,instanceId) != 0;
     }

     function ownerOfToken(uint typeId, uint instanceId) public constant returns (address) {
       return tokenOwner[buildTokenId(typeId,instanceId)];
     }

     function buildTokenId(uint typeId, uint instanceId) public pure returns (uint256) {
       return uint256(keccak256(typeId, '|', instanceId));
     }

}
