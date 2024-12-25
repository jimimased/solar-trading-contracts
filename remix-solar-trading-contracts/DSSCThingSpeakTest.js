const DSSCThingSpeakTest = {
    // ThingSpeak settings
    THINGSPEAK_URL: "https://api.thingspeak.com/channels/2336245/fields/1.json",
    THINGSPEAK_API_KEY: "WXEER0TQBX3D6RYY",
    
    // Your deployed contract address on Amoy
    CONTRACT_ADDRESS: "0xf02d91e309ad69a4f738b6e4f62e35a66e9d331e", // Your contract address
    
    // Initialize
    init: async function() {
        try {
            // Check if we're on Amoy
            const chainId = await web3.eth.getChainId();
            if (chainId !== 80002) {
                throw new Error("Please connect to Amoy testnet");
            }

            // Get account
            const accounts = await web3.eth.getAccounts();
            this.account = accounts[0];
            
            console.log("Connected to Amoy with account:", this.account);
            return true;
        } catch (error) {
            console.error("Initialization error:", error);
            return false;
        }
    },

    // Fetch ThingSpeak data
    fetchThingSpeakData: async function() {
        try {
            const response = await fetch(`${this.THINGSPEAK_URL}?api_key=${this.THINGSPEAK_API_KEY}&results=1`);
            const data = await response.json();
            console.log("ThingSpeak data:", data);
            return data.feeds[0];
        } catch (error) {
            console.error("ThingSpeak fetch error:", error);
            return null;
        }
    },

    // Register new DSSC
    registerDSSC: async function() {
        try {
            // Get ThingSpeak data
            const thingspeakData = await this.fetchThingSpeakData();
            if (!thingspeakData) throw new Error("No ThingSpeak data");

            const voltage = parseInt(thingspeakData.field1);
            const powerRating = (voltage * voltage) / 1000; // P=V²/R
            const ivCurveHash = web3.utils.sha3(JSON.stringify(thingspeakData));

            // Prepare transaction
            const tx = await contract.methods.registerDSSCWithVoltage(
                ivCurveHash,
                powerRating,
                voltage,
                JSON.stringify(thingspeakData)
            ).send({
                from: this.account,
                gas: 3000000,
                gasPrice: await web3.eth.getGasPrice()
            });

            console.log("DSSC Registration tx:", tx.transactionHash);
            return tx;
        } catch (error) {
            console.error("Registration error:", error);
            return null;
        }
    },

    // Get DSSC details
    getDSSCDetails: async function(tokenId) {
        try {
            const data = await contract.methods.getDSSCData(tokenId).call();
            return {
                voltage: web3.utils.fromWei(data.voltage, 'ether'),
                powerRating: web3.utils.fromWei(data.powerRating, 'ether'),
                timestamp: new Date(data.timestamp * 1000).toISOString(),
                thingspeakData: data.thingspeakData
            };
        } catch (error) {
            console.error("Error getting DSSC details:", error);
            return null;
        }
    }
};

// Main test function
async function runAmoyTest() {
    console.log("Starting Amoy Testnet Test...");
    
    // Initialize
    if (!await DSSCThingSpeakTest.init()) {
        console.error("Failed to initialize");
        return;
    }

    try {
        // Register new DSSC
        console.log("Registering new DSSC...");
        const regResult = await DSSCThingSpeakTest.registerDSSC();
        if (!regResult) {
            console.error("Registration failed");
            return;
        }

        // Get token ID from event
        const tokenId = regResult.events.DSSCRegistered.returnValues.tokenId;
        console.log("New token ID:", tokenId);

        // Get details
        console.log("Getting DSSC details...");
        const details = await DSSCThingSpeakTest.getDSSCDetails(tokenId);
        console.log("DSSC Details:", details);

    } catch (error) {
        console.error("Test error:", error);
    }
}

// Export for Remix console
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { DSSCThingSpeakTest, runAmoyTest };
}