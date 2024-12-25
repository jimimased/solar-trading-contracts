// deployment.js
const Web3 = require('web3');
const web3 = new Web3('https://polygon-amoy.core.chainstack.com/d518331e9d59351af11a0c61ea3bef72');

const privateKey = '88bb9958ef25ebe03c5023a8339148dbca909efc2b8ae879bf2307f8bd73daee';
const walletAddress = '0xb5fd9A3b4cc07Fa5fbEa01aCC3A8701192e86744';

async function deployContract() {
    const account = web3.eth.accounts.privateKeyToAccount(privateKey);
    web3.eth.accounts.wallet.add(account);
    
    const DSSCIdentity = new web3.eth.Contract(CONTRACT_ABI);
    
    const deploy = DSSCIdentity.deploy({
        data: CONTRACT_BYTECODE,
        arguments: [walletAddress] // initialOwner parameter
    });

    const gas = await deploy.estimateGas();
    
    const contract = await deploy.send({
        from: walletAddress,
        gas: gas
    });

    console.log('Contract deployed at:', contract.options.address);
    return contract;
}