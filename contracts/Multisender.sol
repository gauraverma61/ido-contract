// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSender is Ownable {
    /**
     * @notice Send ERC20 tokens to multiple addresses
     * @param token The address of the ERC20 token contract
     * @param recipients The list of recipient addresses
     * @param amounts The list of amounts to send, where amounts[i] corresponds to recipients[i]
     */
    function multiSend(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        
        IERC20 erc20 = IERC20(token);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than zero");
            require(erc20.transferFrom(msg.sender, recipients[i], amounts[i]), "Transfer failed");
        }
    }
}
