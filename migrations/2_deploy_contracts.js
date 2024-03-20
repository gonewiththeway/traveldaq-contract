const TraveldqToken = artifacts.require("TraveldqToken");
const USDC = artifacts.require("./usdc.sol");

module.exports = async (deployer, network, accounts) => {


  if (network !== 'mumbai') {
    // Deploy the USDC contract only if it's not the Mumbai network
    await deployer.deploy(USDC, {gas: 6721975});
    const usdc = await USDC.deployed();
    usdcAddress = usdc.address;
    console.log("USDC deployed at:", usdcAddress);
  } else {
    // If it's Mumbai network, set the USDC address manually to a pre-deployed contract address
    usdcAddress = '0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97';
    console.log("Using pre-deployed USDC at:", usdcAddress);
  }

  await deployer.deploy(TraveldqToken, USDC.address, accounts[1], accounts[2], {gas: 6721975});

  console.log("usdc address: %s", USDC.address);
  console.log("TraveldqToken address: %s", TraveldqToken.address);

  //
//   usdc address: 0x123332519171B2bcDc3a94472FB472a46A05a104
// TraveldqToken address: 0x47f3253c07C5635268D24bD46A89485a5a948110
};
