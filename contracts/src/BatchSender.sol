// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchSender {
    /// @notice Send equal amounts of ETH to multiple recipients
    /// @param recipients Array of recipient addresses
    function sendEqual(address[] calldata recipients) external payable {
        require(recipients.length > 0, "No recipients");
        
        uint256 amountPerRecipient = msg.value / recipients.length;
        require(amountPerRecipient > 0, "Amount too small");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
        }
    }
    
    /// @notice Send specific amounts to multiple recipients
    /// @param recipients Array of recipient addresses
    /// @param amounts Array of amounts to send (must match recipients length)
    function sendCustom(address[] calldata recipients, uint256[] calldata amounts) external payable {
        require(recipients.length == amounts.length, "Length mismatch");
        
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalRequired += amounts[i];
        }
        require(msg.value >= totalRequired, "Insufficient value");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
        }
    }
}
