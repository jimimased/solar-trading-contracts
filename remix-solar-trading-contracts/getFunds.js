const axios = require('axios');

// Your configuration
const YOUR_ADDRESS = '0xb5fd9A3b4cc07Fa5fbEa01aCC3A8701192e86744';  // Replace with your full address
const CHAINSTACK_API_KEY = 'I5yScOsz.HXsJfEg0MRzoqme0oquhODwgyUUnLgMA';

async function getSepoliaTestETH() {
    try {
        const response = await axios.post(
            'https://api.chainstack.com/v1/faucet/sepolia',
            { address: YOUR_ADDRESS },
            {
                headers: {
                    'Authorization': `Bearer ${CHAINSTACK_API_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('Success! Transaction URL:', response.data.url);
        console.log('Wait for transaction to complete before deploying contract');
        return true;
    } catch (error) {
        console.error('Error getting test ETH:', error.response?.data || error.message);
        return false;
    }
}

// Run the script
getSepoliaTestETH();