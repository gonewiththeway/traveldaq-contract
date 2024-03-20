const TraveldqToken = artifacts.require("./TraveldqToken");
const Usdc = artifacts.require("./usdc.sol");

contract("TraveldqToken", ([deployer, seller, buyer, airlinesAddress, traveldaqAddress]) => {
    let traveldqToken;
    let usdc;
    const ticketPrice = web3.utils.toBN(web3.utils.toWei('100', 'ether')); // Assuming USDC has 18 decimals

    beforeEach(async () => {
        usdc = await Usdc.new();
        traveldqToken = await TraveldqToken.new(usdc.address, airlinesAddress, traveldaqAddress);
        // await traveldqToken.setAirlinesAddress(airlinesAddress);
        // await traveldqToken.setTraveldqAddress(traveldaqAddress);

        airlineFeePercentage = 5;
        traveldqFeePercentage = 15;

        await traveldqToken.setDistributionRatios(airlineFeePercentage, traveldqFeePercentage);

        // Mint USDC tokens to buyer
        await usdc.transfer(buyer, ticketPrice.muln(2)); // Minting more than the sale price for the buyer
        
        // Mint a ticket to the seller
        await traveldqToken.mintTicket(seller, "AA", "123ABC", Date.now() + 86400, Date.now() + 86400 * 2);
    });

    it("should allow a buyer to purchase a ticket when approved", async () => {
        const tokenId = 0; // Assuming the first minted token has ID 0

        // Approve traveldqToken contract to spend buyer's USDC
        await usdc.approve(traveldqToken.address, ticketPrice, { from: buyer });

        // Seller approves the contract to transfer the token on their behalf
        await traveldqToken.approve(traveldqToken.address, tokenId, { from: seller });

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
        const airlinesBalance = await usdc.balanceOf(airlinesAddress); // Assuming deployer is the owner
        assert(airlinesBalance.eq(airlineFee), "Incorrect airlines balance after sale");

        // Check USDC balance of the contract
        const traveldaqBalance = await usdc.balanceOf(traveldaqAddress);
        assert(traveldaqBalance.eq(traveldqFee), "Incorrect traveldaq balance after sale");
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

    it("should fail to sell a ticket when the buyer has not approved USDC spend", async () => {
        const tokenId = 0; // Assuming the first minted token has ID 0
    
        // Note: No USDC approval from the buyer in this test case
    
        try {
            // Buyer attempts to purchase the ticket without USDC approval
            await traveldqToken.sellTicket(tokenId, buyer, ticketPrice, { from: buyer });
            assert.fail("The transaction should have failed");
        } catch (error) {
            assert.include(error.message, "revert", "Expected transaction to revert due to lack of USDC spend approval");
        }
    });
    
    it("should fail to sell a ticket when the seller has not approved NFT transfer", async () => {
        const tokenId = 0; // Assuming the first minted token has ID 0
    
        // Approve traveldqToken contract to spend buyer's USDC
        await usdc.approve(traveldqToken.address, ticketPrice, { from: buyer });
    
        // Note: No NFT approval from the seller in this test case
    
        try {
            // Buyer attempts to purchase the ticket without NFT transfer approval from the seller
            await traveldqToken.sellTicket(tokenId, buyer, ticketPrice, { from: buyer });
            assert.fail("The transaction should have failed");
        } catch (error) {
            assert.include(error.message, "revert", "Expected transaction to revert due to lack of NFT transfer approval");
        }
    });
    
});
