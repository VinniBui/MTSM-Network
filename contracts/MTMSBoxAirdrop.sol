// SPDX-License-Identifier: UNLICENSED
//TODO: Change above comment !

pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./MTMS_blindbox.sol";


contract MTMSAirdrop is IERC721Receiver, Ownable { 
    using SafeMath for uint256;
    event PausedContract();
    event Claimed(address claimant, uint256 balance);
    event TrancheAdded(uint256 _trancheId,bytes32 merkleRoot, uint256 totalAmount);
    event TrancheExpired();
    event ResumedContract();
    MTMSBox public token;
    bytes32 public merkleRoot;
    mapping(address => bool)[] public claimed;
    uint256 public trancheId = 0;
    bool private isPaused = false;

    constructor(MTMSBox _token) {
        token = _token;
        claimed.push();
    }

    function seedNewAllocations(bytes32 _merkleRoot, uint256 _sumCheck)
        public
        onlyOwner
        returns (uint256 _trancheId) {
        trancheId++;
        _trancheId = trancheId;
        merkleRoot = _merkleRoot;
        
        //delete claimed;
        claimed.push();

        emit TrancheAdded(_trancheId,_merkleRoot, _sumCheck);
    }

    function expireTranche()
        public
        onlyOwner
    {
        merkleRoot = bytes32(0);
        emit TrancheExpired();
    }
    //Note: Only sender can claim token, this function can be changed later
    function claimWeek(
        uint256 _balance,
        bytes32[] memory _merkleProof
    )
        public
    {
        //check time 
        _claimWeek(msg.sender, _balance, _merkleProof);
        _disburse(msg.sender, _balance);
    }

    function verifyClaim(
        address _liquidityProvider,
        uint256 _balance,
        bytes32[] memory _merkleProof
    )
        public
        view
        returns (bool valid)
    {
        return _verifyClaim(_liquidityProvider, _balance, _merkleProof);
    }

    function _claimWeek(
        address _liquidityProvider,
        uint256 _balance,
        bytes32[] memory _merkleProof
    )
        private
    {
        require(!isPaused,"Contract is being paused");
        require(!claimed[trancheId][_liquidityProvider], "LP has already claimed");
        require(_verifyClaim(_liquidityProvider, _balance, _merkleProof), "Incorrect merkle proof");

        claimed[trancheId][_liquidityProvider] = true;

        emit Claimed(_liquidityProvider, _balance);
    }


    function _verifyClaim(
        address _liquidityProvider,
        uint256 _tokenId,
        bytes32[] memory _merkleProof
    )
        private
        view
        returns (bool valid)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_liquidityProvider, _tokenId));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }


    function _disburse(address _liquidityProvider, uint256 _tokenId) private {
        if (_tokenId > 0) {
            token.safeTransferFrom(address(this),_liquidityProvider,_tokenId);
        } else {
            revert("No balance would be transferred - not going to waste your gas");
        }
    }

    function pauseContract()
        public
        onlyOwner 
        {
        require(!isPaused,"Contract is being paused");
        isPaused = true;
        emit PausedContract();
    }

    function resumeContract()
        public
        onlyOwner 
        {
        require(isPaused,"Contract is not being paused");
        isPaused = false;
        emit ResumedContract();
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}