// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TraveldqToken is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
    uint256 private _nextTokenId;

    IERC20 public usdc; // USDC token interface

    uint256 public airlineFeePercentage = 5; // 5% goes to airlines wallet
    uint256 public traveldqFeePercentage = 5; // 5% goes to travelDaq
    uint256 public timeBeforeBuy = 10800; // 3 hours
    address public airlineUsdcAddress; // airlines usdc address
    address public traveldaqUsdcAddress; // airlines usdc address


    // Metadata structure for each ticket
    struct TicketMetadata {
        string airlineCode;
        string pnr;
        uint256 flightTime;
    }

    function updateAirlineFeePercentage(uint256 _airlineFeePercentage) public onlyOwner {
        airlineFeePercentage = _airlineFeePercentage;
    }

    function updateTraveldqFeePercentage(uint256 _traveldqFeePercentage) public onlyOwner {
        traveldqFeePercentage = _traveldqFeePercentage;
    }

    function updateTimeBeforeBuy(uint256 _timeBeforeBuy) public onlyOwner {
        timeBeforeBuy = _timeBeforeBuy;
    }

    function updateAirlinesUsdcAddress(address _airlineUsdcAddress) public onlyOwner {
        airlineUsdcAddress = _airlineUsdcAddress;
    }

    function updateTraveldaqUsdcAddress(address _traveldaqUsdcAddress) public onlyOwner {
        traveldaqUsdcAddress = _traveldaqUsdcAddress;
    }

    mapping(uint256 => TicketMetadata) private _ticketDetails;

    constructor(address initialOwner, address usdcAddress, uint256 _timeBeforeBuy)
        ERC721("TraveldqToken", "TDT")
        Ownable(initialOwner)
    {
        transferOwnership(initialOwner);
        usdc = IERC20(usdcAddress);
        timeBeforeBuy = _timeBeforeBuy; // 3 hours is 10800
    }

    function mintTicket(address to, string memory airlineCode, string memory pnr, uint256 flightTime) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _ticketDetails[tokenId] = TicketMetadata(airlineCode, pnr, flightTime);
        _safeMint(to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sellTicket(uint256 tokenId, address buyer, uint256 salePrice) public {
        // requires isApproved in erc721 
        require(_isAuthorized(_ownerOf(tokenId), _msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(block.timestamp <= _ticketDetails[tokenId].flightTime - 3 hours, "Resale prohibited close to flight time");
        require(usdc.balanceOf(buyer) >= salePrice, "Buyer does not have enough money");

        uint256 airlineFee = salePrice * airlineFeePercentage * 10**16; // no percentage here as we did 10**16 above.
        uint256 traveldqFee = salePrice * traveldqFeePercentage * 10**16 ; // no percentage here as we did 10**16 above.
        uint256 sellerRevenue = (salePrice * 10**18) - airlineFee - traveldqFee; // multiplying salesprice by 10**18 here 

        // require isApproved in erc20
        usdc.transferFrom(buyer, airlineUsdcAddress, airlineFee); // airlines
        // require isApproved in erc20
        usdc.transferFrom(buyer, _ownerOf(tokenId), sellerRevenue); // seller
        // require isApproved in erc20
        usdc.transferFrom(buyer, traveldaqUsdcAddress, traveldqFee); // traveldaq

        _transfer(_msgSender(), buyer, tokenId);
    }

    function cancelTicket(uint256 tokenId) public {
        require(_isAuthorized(owner(), _msgSender(), tokenId) , "ERC721: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function setDistributionRatios(uint256 newAirlineFeePercentage, uint256 newTraveldqFeePercentage) public onlyOwner {
        airlineFeePercentage = newAirlineFeePercentage;
        traveldqFeePercentage = newTraveldqFeePercentage;
    }

    function getTicketDetails(uint256 tokenId) public view returns (TicketMetadata memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721Metadata: Query for nonexistent token");
        return _ticketDetails[tokenId];
    }

    // The following functions are overrides required by Solidity.
    function _update(
      address to,
      uint256 tokenId,
      address auth
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) 
    {
        require(_ticketDetails[tokenId].flightTime - 3 hours > block.timestamp, "Ticket sales are closed");
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
