// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DSSCThingSpeakIdentity is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Enhanced SolarCell struct with voltage data
    struct SolarCell {
        string ivCurveHash;      // Hash of the IV curve data
        uint256 timestamp;       // Registration timestamp
        uint256 powerRating;     // Power rating in watts (scaled by 1e6)
        bool isVerified;         // Verification status
        uint256 voltage;         // ThingSpeak voltage reading (in mV)
        string thingspeakData;   // Raw ThingSpeak JSON data
        uint256 lastUpdateTime;  // Last ThingSpeak update timestamp
        uint256 channelId;       // ThingSpeak channel ID
    }

    // Mapping from token ID to DSSC data
    mapping(uint256 => SolarCell) public cells;
    
    // ThingSpeak configuration
    string public constant THINGSPEAK_CHANNEL = "2336245";
    string public constant THINGSPEAK_API_KEY = "WXEER0TQBX3D6RYY";
    
    // Events for tracking
    event DSSCRegistered(
        uint256 indexed tokenId, 
        string ivCurveHash, 
        uint256 voltage,
        uint256 timestamp
    );
    event DSSCVerified(uint256 indexed tokenId, bool status);
    event PowerRatingUpdated(uint256 indexed tokenId, uint256 newRating);
    event VoltageUpdated(
        uint256 indexed tokenId, 
        uint256 newVoltage, 
        uint256 timestamp
    );

    constructor(address initialOwner) 
        ERC721("DSSC ThingSpeak Identity", "DSSC-TS") 
        Ownable(initialOwner)
    {}

    // Check if token exists
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    // Register new DSSC with ThingSpeak data
    function registerDSSCWithVoltage(
        string memory ivCurveHash,
        uint256 powerRating,
        uint256 voltage,
        string memory thingspeakData
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        
        cells[newTokenId] = SolarCell({
            ivCurveHash: ivCurveHash,
            timestamp: block.timestamp,
            powerRating: powerRating,
            isVerified: false,
            voltage: voltage,
            thingspeakData: thingspeakData,
            lastUpdateTime: block.timestamp,
            channelId: 2336245
        });

        emit DSSCRegistered(
            newTokenId, 
            ivCurveHash, 
            voltage,
            block.timestamp
        );
        return newTokenId;
    }

    // Update voltage reading from ThingSpeak
    function updateVoltageReading(
        uint256 tokenId,
        uint256 newVoltage,
        string memory newThingspeakData
    ) public onlyOwner {
        require(exists(tokenId), "DSSC: Token does not exist");
        
        cells[tokenId].voltage = newVoltage;
        cells[tokenId].thingspeakData = newThingspeakData;
        cells[tokenId].lastUpdateTime = block.timestamp;

        emit VoltageUpdated(tokenId, newVoltage, block.timestamp);
    }

    // Verify a DSSC's authenticity with ThingSpeak data
    function verifyDSSCWithVoltage(
        uint256 tokenId,
        string memory currentHash,
        uint256 currentVoltage
    ) public view returns (bool) {
        require(exists(tokenId), "DSSC: Token does not exist");
        
        SolarCell memory cell = cells[tokenId];
        
        // Verify both hash and voltage within tolerance
        bool hashMatch = keccak256(bytes(cell.ivCurveHash)) == 
                        keccak256(bytes(currentHash));
                        
        // Allow 5% voltage tolerance
        uint256 tolerance = cell.voltage * 5 / 100;
        bool voltageMatch = (currentVoltage >= cell.voltage - tolerance) && 
                          (currentVoltage <= cell.voltage + tolerance);
                          
        return hashMatch && voltageMatch;
    }

    // Update power rating (only owner)
    function updatePowerRating(
        uint256 tokenId,
        uint256 newRating
    ) public onlyOwner {
        require(exists(tokenId), "DSSC: Token does not exist");
        cells[tokenId].powerRating = newRating;
        emit PowerRatingUpdated(tokenId, newRating);
    }

    // Set verification status (only owner)
    function setVerificationStatus(
        uint256 tokenId,
        bool status
    ) public onlyOwner {
        require(exists(tokenId), "DSSC: Token does not exist");
        cells[tokenId].isVerified = status;
        emit DSSCVerified(tokenId, status);
    }

    // Get complete DSSC data including ThingSpeak info
    function getDSSCData(uint256 tokenId) 
        public 
        view 
        returns (
            string memory ivCurveHash,
            uint256 timestamp,
            uint256 powerRating,
            bool isVerified,
            uint256 voltage,
            string memory thingspeakData,
            uint256 lastUpdateTime,
            uint256 channelId
        ) 
    {
        require(exists(tokenId), "DSSC: Token does not exist");
        SolarCell memory cell = cells[tokenId];
        return (
            cell.ivCurveHash,
            cell.timestamp,
            cell.powerRating,
            cell.isVerified,
            cell.voltage,
            cell.thingspeakData,
            cell.lastUpdateTime,
            cell.channelId
        );
    }

    // Get ThingSpeak configuration
    function getThingSpeakConfig() 
        public 
        pure 
        returns (
            string memory channelId,
            string memory apiKey
        ) 
    {
        return (THINGSPEAK_CHANNEL, THINGSPEAK_API_KEY);
    }

    // Calculate power from voltage (helper function)
    function calculatePower(uint256 voltage) 
        public 
        pure 
        returns (uint256) 
    {
        // Example calculation: P = V²/R (assuming 1kΩ resistance)
        return (voltage * voltage) / 1000; // Result in microwatts
    }
}