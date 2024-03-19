const TraveldqToken = artifacts.require("./TraveldqToken");
const MockUSDC = artifacts.require("./usdc.sol");

contract("TraveldqToken", ([deployer, seller, buyer]) => {
    let traveldqToken;
    let usdc;
    const ticketPrice = web3.utils.toBN(web3.utils.toWei('100', 'ether')); // Assuming USDC has 18 decimals

    beforeEach(async () => {
        usdc = await MockUSDC.new();
        traveldqToken = await TraveldqToken.new(usdc.address);

        // Mint USDC tokens to buyer
        await usdc.transfer(buyer, ticketPrice.muln(2)); // Minting more than the sale price for the buyer

        // Mint a ticket to the seller
        await traveldqToken.mintTicket(seller, "AA", "123ABC", Date.now() + 86400, Date.now() + 86400 * 2);
    });

    it("should allow a buyer to purchase a ticket when approved", async () => {
        const tokenId = 0; // Assuming the first minted token has ID 0

        // Approve traveldqToken contract to spend buyer's USDC
        await usdc.approve(traveldqToken.address, ticketPrice, { from: buyer });

        // Buyer purchases the ticket
        await traveldqToken.sellTicket(tokenId, buyer, ticketPrice, { from: buyer });

        // Check new owner of the ticket
        const newOwner = await traveldqToken.ownerOf(tokenId);
        assert.equal(newOwner, buyer, "Ownership not transferred to buyer");

        // Calculate expected fee distributions
        const airlineFee = ticketPrice.muln(airlineFeePercentage).divn(100);
        const traveldqFee = ticketPrice.muln(traveldqFeePercentage).divn(100);
        const sellerRevenue = ticketPrice.sub(airlineFee).sub(traveldqFee);

        // Check USDC balance of the seller
        const sellerBalance = await usdc.balanceOf(seller);
        assert(sellerBalance.eq(sellerRevenue), "Incorrect seller balance after sale");

        // Check USDC balance of the contract owner
        const ownerBalance = await usdc.balanceOf(deployer); // Assuming deployer is the owner
        assert(ownerBalance.eq(airlineFee), "Incorrect owner balance after sale");

        // Check USDC balance of the contract
        const contractBalance = await usdc.balanceOf(traveldqToken.address);
        assert(contractBalance.eq(traveldqFee), "Incorrect contract balance after sale");
    });   

    it("should fail to sell a ticket when the buyer has not approved USDC spend", async () => {
        const tokenId = 0; // Assuming the first minted token has ID 0

        try {
            // Buyer attempts to purchase the ticket without USDC approval
            await traveldqToken.sellTicket(tokenId, buyer, ticketPrice, { from: buyer });
            assert.fail("The transaction should have failed");
        } catch (error) {
            assert.include(error.message, "revert", "Expected transaction to revert");
        }
    });
});
