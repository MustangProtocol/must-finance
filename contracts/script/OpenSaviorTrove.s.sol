// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IBorrowerOperations} from "src/Interfaces/IBorrowerOperations.sol";
/**
 * Open a trove with SaviorToken collateral and mint MUST.
 * Prereqs: sagaTester has ~35M+ SAVIOR. Run:
 *
 * forge script script/OpenSaviorTrove.s.sol:OpenSaviorTrove --rpc-url https://sagaevm.jsonrpc.sagarpc.io --broadcast --account sagaTester --with-gas-price 0 --priority-gas-price 0 --gas-estimate-multiplier 10 --skip-simulation
 */
contract OpenSaviorTrove is Script {
    address constant SAVIOR_TOKEN_DEFAULT = 0x7A609ED6D3F679f176c39012BB8ba043Cc9855b9;
    address constant BOLD_TOKEN = 0xA8b56ce258a7f55327BdE886B0e947EE059ca434;
    address constant SAVIOR_BORROWER_OPS_DEFAULT = 0x55edCb7f83b97911F5272E3dD217A1Ec43952D5d;

    function run() external {
        address owner = msg.sender;
        address saviorToken = vm.envOr("SAVIOR_TOKEN", SAVIOR_TOKEN_DEFAULT);
        IBorrowerOperations bo = IBorrowerOperations(
            vm.envOr("BORROWER_OPS", SAVIOR_BORROWER_OPS_DEFAULT)
        );
        uint256 collAmount = vm.envOr("COLL_AMOUNT", uint256(50_000_000e18));
        uint256 mustAmount = vm.envOr("MUST_AMOUNT", uint256(150_000_000e18));

        IERC20 savior = IERC20(saviorToken);
        require(savior.balanceOf(owner) >= collAmount, "Insufficient SAVIOR balance");

        vm.startBroadcast();

        savior.approve(address(bo), collAmount);
        uint256 troveId = bo.openTrove(
            owner,
            0,              // ownerIndex
            collAmount,
            mustAmount,
            0,               // upperHint (0,0 works for empty/first trove)
            0,               // lowerHint
            0.05e18,         // 5% annual interest rate
            type(uint256).max, // maxUpfrontFee - accept any
            address(0),
            address(0),
            address(0)
        );

        vm.stopBroadcast();

        console2.log("Trove opened, troveId:", troveId);
        console2.log("MUST balance:", IERC20(BOLD_TOKEN).balanceOf(owner));
    }
}
