// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Usdc is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
    // Optional: Override the decimals function if you want a different number of decimals
    // function decimals() public view virtual override returns (uint8) {
    //     return 6; // Example: USDC often uses 6 decimals
    // }
}
