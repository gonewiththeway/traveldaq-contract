// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.1;

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
    address public airlinesAddress;
    address public traveldqAddress;

    // Metadata structure for each ticket
    struct TicketMetadata {
        string airlineCode;
        string pnr;
        uint256 travelDate;
        uint256 flightTime;
    }

    // Setter for airlinesAddress
    function setAirlinesAddress(address _airlinesAddress) public onlyOwner {
        require(_airlinesAddress != address(0), "Invalid address");
        airlinesAddress = _airlinesAddress;
    }

    // Setter for traveldqAddress
    function setTraveldqAddress(address _traveldqAddress) public onlyOwner {
        require(_traveldqAddress != address(0), "Invalid address");
        traveldqAddress = _traveldqAddress;
    }

    mapping(uint256 => TicketMetadata) private _ticketDetails;

    constructor(address usdcAddress, address _airlinesAddress, address _traveldqAddress)
        ERC721("TraveldqToken", "TDT")
    {
        transferOwnership(_msgSender());
        usdc = IERC20(usdcAddress);
        airlinesAddress = _airlinesAddress;
        traveldqAddress = _traveldqAddress;
    }


    function mintTicket(address to, string memory airlineCode, string memory pnr, uint256 travelDate, uint256 flightTime) public onlyOwner {
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
        require(buyer != _owners[tokenId], "ERC721: buyer can not be the seller");
        require(_isApprovedOrOwner(address(this), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(block.timestamp <= _ticketDetails[tokenId].flightTime - 3 hours, "Resale prohibited close to flight time");

        uint256 airlineFee = (salePrice * airlineFeePercentage) / 100;
        uint256 traveldqFee = (salePrice * traveldqFeePercentage) / 100;
        uint256 sellerRevenue = salePrice - airlineFee - traveldqFee;

        usdc.transferFrom(buyer, airlinesAddress, airlineFee);
        usdc.transferFrom(buyer, traveldqAddress, traveldqFee);
        usdc.transferFrom(buyer, _owners[tokenId], sellerRevenue);

        _transfer(_owners[tokenId], buyer, tokenId);
    }

    function setDistributionRatios(uint256 newAirlineFeePercentage, uint256 newTraveldqFeePercentage) public onlyOwner {
        airlineFeePercentage = newAirlineFeePercentage;
        traveldqFeePercentage = newTraveldqFeePercentage;
    }

    function getTicketDetails(uint256 tokenId) public view returns (TicketMetadata memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721Metadata: Query for nonexistent token");
        return _ticketDetails[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Pausable, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted) 
        // being transferred to registered candidate
    }


}
