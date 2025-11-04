// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseZapper} from "src/Zappers/BaseZapper.sol";
import {WETHZapper} from "src/Zappers/WETHZapper.sol";
import {LeverageWETHZapper} from "src/Zappers/LeverageWETHZapper.sol";
import {WrappedTokenZapper} from "src/Zappers/WrappedTokenZapper.sol";
import {IZapper} from "src/Zappers/Interfaces/IZapper.sol";
import {UseDeployment} from "test/Utils/UseDeployment.sol";
import "src/Dependencies/Constants.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SimulateZapper is Script {
    function run() external {
        console.log("msgsender:", msg.sender);
        WrappedTokenZapper zapper = WrappedTokenZapper(payable(0xF4ae7336ab0fA33c3fc9b289612072C8928Ee512)); // WrappedTokenZapper for SAGA token
        
        IERC20 collToken = IERC20(0xA19377761FED745723B90993988E04d641c2CfFE); // SAGA token
        uint256 allowance = collToken.allowance(msg.sender, address(zapper));

        console.log("allowance:", allowance);

        console.log("balance:", collToken.balanceOf(msg.sender));

        console.log("colltoken address:", address(collToken));

        console.log("zapper address:", address(zapper));

        console.log("branch id:", zapper.troveManager().branchId());

        vm.broadcast();
        zapper.openTroveWithRawETH(IZapper.OpenTroveParams({
            owner: msg.sender,
            ownerIndex: 0,
            collAmount: 4990000000,
            boldAmount: 200 * DECIMAL_PRECISION,
            upperHint: 0,
            lowerHint: 0,
            annualInterestRate: 1 * _1pct,
            batchManager: address(0),
            maxUpfrontFee: type(uint256).max,
            addManager: address(0),
            removeManager: address(0),
            receiver: address(0)
        }));
    }
}