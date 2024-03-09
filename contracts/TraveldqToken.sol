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

    uint256 public airlineFeePercentage = 5;
    uint256 public traveldqFeePercentage = 5;

    // Metadata structure for each ticket
    struct TicketMetadata {
        string airlineCode;
        string pnr;
        uint256 travelDate;
        uint256 flightTime;
    }

    mapping(uint256 => TicketMetadata) private _ticketDetails;

    constructor(address initialOwner, address usdcAddress)
        ERC721("TraveldqToken", "TDT")
        Ownable(initialOwner)
    {
        transferOwnership(initialOwner);
        usdc = IERC20(usdcAddress);
    }


    function mintTicket(address to, string memory airlineCode, string memory pnr, uint256 travelDate, uint256 flightTime, string memory tokenURI) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _ticketDetails[tokenId] = TicketMetadata(airlineCode, pnr, travelDate, flightTime);
        _safeMint(to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sellTicket(uint256 tokenId, address buyer, uint256 salePrice) public {
        require(_isAuthorized(owner(), _msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(block.timestamp <= _ticketDetails[tokenId].flightTime - 3 hours, "Resale prohibited close to flight time");

        uint256 airlineFee = (salePrice * airlineFeePercentage) / 100;
        uint256 traveldqFee = (salePrice * traveldqFeePercentage) / 100;
        uint256 sellerRevenue = salePrice - airlineFee - traveldqFee;

        usdc.transferFrom(buyer, owner(), airlineFee);
        usdc.transferFrom(buyer, _msgSender(), sellerRevenue);
        usdc.transferFrom(buyer, address(this), traveldqFee);

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
        super._update(to, tokenId, auth);
    }

    // function _update(address to, uint256 tokenId, address auth)
    //     internal
    //     override(ERC721, ERC721Enumerable, ERC721Pausable)
    //     returns (address)
    // {
    //     return super._update(to, tokenId, auth);
    // }

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
