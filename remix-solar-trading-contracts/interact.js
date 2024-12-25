// interact.js
async function interactWithContract(contractAddress) {
    const contract = new web3.eth.Contract(CONTRACT_ABI, contractAddress);
    
    // Register new DSSC
    async function registerDSSC(ivCurveHash, powerRating) {
        const tx = await contract.methods.registerDSSC(
            ivCurveHash,
            powerRating
        ).send({
            from: walletAddress,
            gas: 3000000
        });
        return tx;
    }
    
    // Verify DSSC
    async function verifyDSSC(tokenId, currentHash) {
        const result = await contract.methods.verifyDSSC(
            tokenId,
            currentHash
        ).call();
        return result;
    }
    
    return {
        registerDSSC,
        verifyDSSC
    };
}