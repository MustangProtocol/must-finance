// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ICollateralRegistry} from "src/Interfaces/ICollateralRegistry.sol";
import {ITroveManager} from "src/Interfaces/ITroveManager.sol";
import {IAddressesRegistry} from "src/Interfaces/IAddressesRegistry.sol";
import {ITroveNFT} from "src/Interfaces/ITroveNFT.sol";
import {LatestTroveData} from "src/Types/LatestTroveData.sol";

contract InspectTroves is Script {
    ICollateralRegistry constant COLL_REGISTRY = ICollateralRegistry(0xF39bdCfB55374dDb0948a28af00b6474A566Ac22);

    function run() external view {
        uint256 totalActive = COLL_REGISTRY.totalCollaterals();

        console2.log("====================================");
        console2.log("  MUST Finance - Trove Inspector");
        console2.log("====================================");
        console2.log("Active branches:", totalActive);
        console2.log("");

        for (uint256 i = 0; i < totalActive; i++) {
            ITroveManager tm = COLL_REGISTRY.getTroveManager(i);
            IERC20Metadata collToken = COLL_REGISTRY.getToken(i);
            IAddressesRegistry ar = tm.addressesRegistry();
            ITroveNFT troveNFT = ar.troveNFT();

            string memory symbol = collToken.symbol();
            uint256 count = tm.getTroveIdsCount();

            console2.log("------------------------------------");
            console2.log("Branch", i, "-", symbol);
            console2.log("Trove count:", count);

            if (count == 0) {
                console2.log("  (no troves)");
                continue;
            }

            for (uint256 j = 0; j < count; j++) {
                uint256 troveId = tm.getTroveFromTroveIdsArray(j);
                LatestTroveData memory data = tm.getLatestTroveData(troveId);
                address owner = troveNFT.ownerOf(troveId);

                ITroveManager.Status status = tm.getTroveStatus(troveId);
                string memory statusStr;
                if (status == ITroveManager.Status.active) statusStr = "active";
                else if (status == ITroveManager.Status.closedByOwner) statusStr = "closedByOwner";
                else if (status == ITroveManager.Status.closedByLiquidation) statusStr = "closedByLiq";
                else if (status == ITroveManager.Status.zombie) statusStr = "zombie";
                else statusStr = "unknown";

                console2.log("");
                console2.log("  Trove #", j);
                console2.log("    Owner:      ", owner);
                console2.log("    Status:     ", statusStr);
                console2.log("    Collateral: ", data.entireColl, symbol);
                console2.log("    Debt (MUST):", data.entireDebt);
                console2.log("    Interest:   ", data.annualInterestRate, "(annual, raw)");
            }

            console2.log("");
        }

        console2.log("====================================");
        console2.log("  Done.");
        console2.log("====================================");
    }
}
