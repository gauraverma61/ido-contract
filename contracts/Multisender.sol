// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSender {
  
    function multiSend(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        
        IERC20 erc20 = IERC20(token);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than zero");
            require(erc20.transferFrom(msg.sender, recipients[i], amounts[i]), "Transfer failed");
        }
    }
}