// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "../Interfaces/IPriceFeed.sol";

contract FixedPriceFeed is IPriceFeed {
    uint256 public immutable price;
    uint256 public lastGoodPrice;

    constructor(uint256 _price) {
        require(_price > 0, "FixedPriceFeed: price must be > 0");
        price = _price;
        lastGoodPrice = _price;
    }

    function fetchPrice() external view returns (uint256, bool) {
        return (price, false);
    }

    function fetchRedemptionPrice() external view returns (uint256, bool) {
        return (price, false);
    }
}
