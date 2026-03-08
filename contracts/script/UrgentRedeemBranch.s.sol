// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {ICollateralRegistry} from "src/Interfaces/ICollateralRegistry.sol";
import {ITroveManager} from "src/Interfaces/ITroveManager.sol";
import {IAddressesRegistry} from "src/Interfaces/IAddressesRegistry.sol";
import {IBoldToken} from "src/Interfaces/IBoldToken.sol";

contract UrgentRedeemBranch is Script {
    // Fallback used when COLLATERAL_REGISTRY is not provided in env.
    ICollateralRegistry internal constant DEFAULT_COLLATERAL_REGISTRY =
        ICollateralRegistry(0xF39bdCfB55374dDb0948a28af00b6474A566Ac22);

    function run() external {
        uint256 branchId = vm.envUint("BRANCH_ID");
        uint256 minCollOut = _readEnvOrDefault("MIN_COLL_OUT", 0);
        uint256 maxTroves = _readEnvOrDefault("MAX_TROVES", type(uint256).max);
        uint256 boldAmount = _readBoldAmount();

        ICollateralRegistry collateralRegistry = _getCollateralRegistry();
        ITroveManager troveManager = collateralRegistry.allTroveManagerAddresses(branchId);
        require(address(troveManager) != address(0), "Invalid branch/TroveManager");

        uint256 shutdownTime = troveManager.shutdownTime();
        console2.log("Branch ID:", branchId);
        console2.log("TroveManager:", address(troveManager));
        console2.log("Shutdown time:", shutdownTime);
        require(shutdownTime != 0, "Branch is not shut down");

        uint256 troveCount = troveManager.getTroveIdsCount();
        require(troveCount != 0, "No troves in branch");

        uint256 useCount = troveCount < maxTroves ? troveCount : maxTroves;
        uint256[] memory troveIds = new uint256[](useCount);
        for (uint256 i = 0; i < useCount; i++) {
            troveIds[i] = troveManager.getTroveFromTroveIdsArray(i);
        }

        IAddressesRegistry addressesRegistry = troveManager.addressesRegistry();
        IBoldToken boldToken = addressesRegistry.boldToken();
        uint256 senderBal = boldToken.balanceOf(msg.sender);
        require(senderBal >= boldAmount, "Insufficient BOLD balance");

        console2.log("BOLD in (wei):", boldAmount);
        console2.log("Min collateral out (wei):", minCollOut);
        console2.log("Trove IDs provided:", useCount);

        vm.startBroadcast();
        troveManager.urgentRedemption(boldAmount, troveIds, minCollOut);
        vm.stopBroadcast();

        console2.log("Urgent redemption submitted.");
    }

    function _readBoldAmount() internal view returns (uint256) {
        // Prefer AMOUNT_WEI to avoid ambiguity.
        try vm.envUint("AMOUNT_WEI") returns (uint256 amountWei) {
            return amountWei;
        } catch {
            uint256 amount = vm.envUint("AMOUNT");
            return amount * 1e18;
        }
    }

    function _readEnvOrDefault(string memory key, uint256 defaultValue) internal view returns (uint256) {
        try vm.envUint(key) returns (uint256 value) {
            return value;
        } catch {
            return defaultValue;
        }
    }

    function _getCollateralRegistry() internal view returns (ICollateralRegistry) {
        try vm.envAddress("COLLATERAL_REGISTRY") returns (address registry) {
            return ICollateralRegistry(registry);
        } catch {
            return DEFAULT_COLLATERAL_REGISTRY;
        }
    }
}
