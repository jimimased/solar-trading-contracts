// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DSSCIdentity is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Struct to store DSSC data
    struct SolarCell {
        string ivCurveHash;      // Hash of the IV curve data
        uint256 timestamp;       // Registration timestamp
        uint256 powerRating;     // Power rating in watts (scaled by 1e6)
        bool isVerified;         // Verification status
    }

    // Mapping from token ID to DSSC data
    mapping(uint256 => SolarCell) public cells;
    
    // Events for tracking
    event DSSCRegistered(uint256 indexed tokenId, string ivCurveHash);
    event DSSCVerified(uint256 indexed tokenId, bool status);
    event PowerRatingUpdated(uint256 indexed tokenId, uint256 newRating);

    constructor(address initialOwner) 
        ERC721("DSSC Identity", "DSSC") 
        Ownable(initialOwner)
    {
        require(
            block.chainid == 80002, 
            "Must deploy on Amoy Testnet"
        );
    }

    // Check if token exists
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    // Get current chain ID (for verification)
    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    // Register a new DSSC
    function registerDSSC(
        string memory ivCurveHash,
        uint256 powerRating
    ) public returns (uint256) {
        require(
            block.chainid == 80002, 
            "Must be on Amoy Testnet"
        );
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        
        cells[newTokenId] = SolarCell({
            ivCurveHash: ivCurveHash,
            timestamp: block.timestamp,
            powerRating: powerRating,
            isVerified: false
        });

        emit DSSCRegistered(newTokenId, ivCurveHash);
        return newTokenId;
    }

    // Verify a DSSC's authenticity
    function verifyDSSC(
        uint256 tokenId,
        string memory currentHash
    ) public view returns (bool) {
        require(exists(tokenId), "DSSC: Token does not exist");
        return keccak256(bytes(cells[tokenId].ivCurveHash)) == 
               keccak256(bytes(currentHash));
    }

    // Update power rating (only owner)
    function updatePowerRating(
        uint256 tokenId,
        uint256 newRating
    ) public onlyOwner {
        require(
            block.chainid == 80002, 
            "Must be on Amoy Testnet"
        );
        require(exists(tokenId), "DSSC: Token does not exist");
        cells[tokenId].powerRating = newRating;
        emit PowerRatingUpdated(tokenId, newRating);
    }

    // Set verification status (only owner)
    function setVerificationStatus(
        uint256 tokenId,
        bool status
    ) public onlyOwner {
        require(
            block.chainid == 80002, 
            "Must be on Amoy Testnet"
        );
        require(exists(tokenId), "DSSC: Token does not exist");
        cells[tokenId].isVerified = status;
        emit DSSCVerified(tokenId, status);
    }

    // Get DSSC data
    function getDSSCData(uint256 tokenId) 
        public 
        view 
        returns (SolarCell memory) 
    {
        require(exists(tokenId), "DSSC: Token does not exist");
        return cells[tokenId];
    }

    // Get contract deployment info
    function getDeploymentInfo() public view returns (
        uint256 chainId,
        address contractAddress,
        address contractOwner
    ) {
        return (
            block.chainid,
            address(this),
            owner()
        );
    }
}