// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "src/AddressesRegistry.sol";
import "src/ActivePool.sol";
import "src/BorrowerOperations.sol";
import "src/TroveManager.sol";
import "src/TroveNFT.sol";
import "src/CollSurplusPool.sol";
import "src/DefaultPool.sol";
import "src/GasPool.sol";
import "src/SortedTroves.sol";
import "src/StabilityPool.sol";
import "src/CollateralRegistry.sol";
import "src/PriceFeeds/FixedPriceFeed.sol";

contract DeploySaviorBranch is Script {
    address constant DEPLOYER        = 0x65F88fDFA29e4eB72AD3b1eD9d43697698d4B28a;
    address constant BOLD_TOKEN      = 0xA8b56ce258a7f55327BdE886B0e947EE059ca434;
    address constant COLL_REGISTRY   = 0xF39bdCfB55374dDb0948a28af00b6474A566Ac22;
    address constant SAVIOR_TOKEN    = 0x7A609ED6D3F679f176c39012BB8ba043Cc9855b9;
    address constant WETH            = 0xeb41D53F14Cb9a67907f2b8b5DBc223944158cCb;
    address constant HINT_HELPERS    = 0xf2A7Cab8056Bcc477872b34F9bE1D1D67A7D109c;
    address constant MULTI_TROVE_GET = 0x651d868eF9D04cA0B2A3bF2BC299B92e58aed8C3;
    address constant GOVERNANCE      = 0x92A857b519F73783E27642c0f4A5DBAc8953e66B;
    address constant METADATA_NFT    = 0x72fa15D8f87C81AcC03304899867F90363F42164;

    function c2(bytes32 salt, bytes memory code, address arg) internal view returns (address) {
        return vm.computeCreate2Address(salt, keccak256(abi.encodePacked(code, abi.encode(arg))));
    }

    function c2(bytes32 salt, bytes memory code, address arg, uint256 arg2) internal view returns (address) {
        return vm.computeCreate2Address(salt, keccak256(abi.encodePacked(code, abi.encode(arg, arg2))));
    }

    function run() external {
        bytes32 salt = keccak256(bytes(vm.envOr("SALT", string("savior"))));

        vm.startBroadcast(DEPLOYER);

        uint256 branchId = CollateralRegistry(COLL_REGISTRY).branches();

        FixedPriceFeed priceFeed = new FixedPriceFeed(5e18);

        AddressesRegistry ar = new AddressesRegistry(
            DEPLOYER,
            1.5e18,  // CCR  150%
            1.1e18,  // MCR  110%
            0.1e18,  // BCR  10%
            1.1e18,  // SCR  110%
            10_000_000_000e18, // debt limit
            0.05e18, // liq penalty SP
            0.1e18   // liq penalty redist
        );

        address a = address(ar);
        ar.setAddresses(IAddressesRegistry.AddressVars({
            collToken:            IERC20Metadata(SAVIOR_TOKEN),
            borrowerOperations:   IBorrowerOperations(c2(salt, type(BorrowerOperations).creationCode, a)),
            troveManager:         ITroveManager(c2(salt, type(TroveManager).creationCode, a, branchId)),
            troveNFT:             ITroveNFT(c2(salt, type(TroveNFT).creationCode, a)),
            metadataNFT:          IMetadataNFT(METADATA_NFT),
            stabilityPool:        IStabilityPool(c2(salt, type(StabilityPool).creationCode, a)),
            priceFeed:            IPriceFeed(address(priceFeed)),
            activePool:           IActivePool(c2(salt, type(ActivePool).creationCode, a)),
            defaultPool:          IDefaultPool(c2(salt, type(DefaultPool).creationCode, a)),
            gasPoolAddress:       c2(salt, type(GasPool).creationCode, a),
            collSurplusPool:      ICollSurplusPool(c2(salt, type(CollSurplusPool).creationCode, a)),
            sortedTroves:         ISortedTroves(c2(salt, type(SortedTroves).creationCode, a)),
            interestRouter:       IInterestRouter(GOVERNANCE),
            hintHelpers:          IHintHelpers(HINT_HELPERS),
            multiTroveGetter:     IMultiTroveGetter(MULTI_TROVE_GET),
            collateralRegistry:   ICollateralRegistry(COLL_REGISTRY),
            boldToken:            IBoldToken(BOLD_TOKEN),
            WETH:                 IWETH(WETH)
        }));

        BorrowerOperations bo = new BorrowerOperations{salt: salt}(IAddressesRegistry(a));
        TroveManager       tm = new TroveManager{salt: salt}(IAddressesRegistry(a), branchId);
        new TroveNFT{salt: salt}(IAddressesRegistry(a));
        StabilityPool      sp = new StabilityPool{salt: salt}(IAddressesRegistry(a));
        ActivePool         ap = new ActivePool{salt: salt}(IAddressesRegistry(a));
        new DefaultPool{salt: salt}(IAddressesRegistry(a));
        new GasPool{salt: salt}(IAddressesRegistry(a));
        new CollSurplusPool{salt: salt}(IAddressesRegistry(a));
        new SortedTroves{salt: salt}(IAddressesRegistry(a));

        vm.stopBroadcast();

        console2.log("=== Savior Branch Deployed ===");
        console2.log("BranchId:           ", branchId);
        console2.log("FixedPriceFeed:     ", address(priceFeed));
        console2.log("AddressesRegistry:  ", a);
        console2.log("BorrowerOperations: ", address(bo));
        console2.log("TroveManager:       ", address(tm));
        console2.log("StabilityPool:      ", address(sp));
        console2.log("ActivePool:         ", address(ap));
        console2.log("");
        console2.log("=== GNOSIS SAFE TX #1: addCollateral ===");
        console2.log("Target:", COLL_REGISTRY);
        console2.log("  arg0 (token):", SAVIOR_TOKEN);
        console2.log("  arg1 (tm):  ", address(tm));
        console2.log("");
        console2.log("=== GNOSIS SAFE TX #2: setBranchAddressesInBoldToken ===");
        console2.log("Target:", COLL_REGISTRY);
        console2.log("  tm:", address(tm));
        console2.log("  sp:", address(sp));
        console2.log("  bo:", address(bo));
        console2.log("  ap:", address(ap));
    }
}
