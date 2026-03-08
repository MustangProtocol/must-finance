// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
import "src/SaviorToken.sol";

contract SaviorBranchForkTest is Test {
    address constant BOLD_TOKEN      = 0xA8b56ce258a7f55327BdE886B0e947EE059ca434;
    address constant COLL_REGISTRY   = 0xF39bdCfB55374dDb0948a28af00b6474A566Ac22;
    address constant SAVIOR_TOKEN    = 0x7A609ED6D3F679f176c39012BB8ba043Cc9855b9;
    address constant WETH            = 0xeb41D53F14Cb9a67907f2b8b5DBc223944158cCb;
    address constant HINT_HELPERS    = 0xf2A7Cab8056Bcc477872b34F9bE1D1D67A7D109c;
    address constant MULTI_TROVE_GET = 0x651d868eF9D04cA0B2A3bF2BC299B92e58aed8C3;
    address constant GOVERNANCE      = 0x92A857b519F73783E27642c0f4A5DBAc8953e66B;
    address constant METADATA_NFT    = 0x72fa15D8f87C81AcC03304899867F90363F42164;

    bytes32 salt = keccak256("savior");
    CollateralRegistry registry;
    SaviorToken saviorToken;

    BorrowerOperations bo;
    TroveManager tm;
    StabilityPool sp;
    ActivePool ap;

    function c2(bytes memory code, address arg) internal view returns (address) {
        return computeCreate2Address(salt, keccak256(abi.encodePacked(code, abi.encode(arg))));
    }

    function c2(bytes memory code, address arg, uint256 arg2) internal view returns (address) {
        return computeCreate2Address(salt, keccak256(abi.encodePacked(code, abi.encode(arg, arg2))));
    }

    function setUp() public {
        vm.createSelectFork("https://sagaevm.jsonrpc.sagarpc.io");
        registry = CollateralRegistry(COLL_REGISTRY);
        saviorToken = SaviorToken(SAVIOR_TOKEN);
    }

    function _deployBranch() internal returns (uint256 branchId) {
        branchId = registry.branches();

        FixedPriceFeed priceFeed = new FixedPriceFeed(5e18);
        AddressesRegistry ar = new AddressesRegistry(
            address(this), 1.5e18, 1.1e18, 0.1e18, 1.1e18,
            10_000_000_000e18, 0.05e18, 0.1e18
        );

        address a = address(ar);
        ar.setAddresses(IAddressesRegistry.AddressVars({
            collToken:            IERC20Metadata(SAVIOR_TOKEN),
            borrowerOperations:   IBorrowerOperations(c2(type(BorrowerOperations).creationCode, a)),
            troveManager:         ITroveManager(c2(type(TroveManager).creationCode, a, branchId)),
            troveNFT:             ITroveNFT(c2(type(TroveNFT).creationCode, a)),
            metadataNFT:          IMetadataNFT(METADATA_NFT),
            stabilityPool:        IStabilityPool(c2(type(StabilityPool).creationCode, a)),
            priceFeed:            IPriceFeed(address(priceFeed)),
            activePool:           IActivePool(c2(type(ActivePool).creationCode, a)),
            defaultPool:          IDefaultPool(c2(type(DefaultPool).creationCode, a)),
            gasPoolAddress:       c2(type(GasPool).creationCode, a),
            collSurplusPool:      ICollSurplusPool(c2(type(CollSurplusPool).creationCode, a)),
            sortedTroves:         ISortedTroves(c2(type(SortedTroves).creationCode, a)),
            interestRouter:       IInterestRouter(GOVERNANCE),
            hintHelpers:          IHintHelpers(HINT_HELPERS),
            multiTroveGetter:     IMultiTroveGetter(MULTI_TROVE_GET),
            collateralRegistry:   ICollateralRegistry(COLL_REGISTRY),
            boldToken:            IBoldToken(BOLD_TOKEN),
            WETH:                 IWETH(WETH)
        }));

        bo = new BorrowerOperations{salt: salt}(IAddressesRegistry(a));
        tm = new TroveManager{salt: salt}(IAddressesRegistry(a), branchId);
        new TroveNFT{salt: salt}(IAddressesRegistry(a));
        sp = new StabilityPool{salt: salt}(IAddressesRegistry(a));
        ap = new ActivePool{salt: salt}(IAddressesRegistry(a));
        new DefaultPool{salt: salt}(IAddressesRegistry(a));
        new GasPool{salt: salt}(IAddressesRegistry(a));
        new CollSurplusPool{salt: salt}(IAddressesRegistry(a));
        new SortedTroves{salt: salt}(IAddressesRegistry(a));
    }

    function _executeGovernance() internal {
        vm.startPrank(GOVERNANCE);
        registry.addCollateral(IERC20Metadata(SAVIOR_TOKEN), ITroveManager(address(tm)));
        registry.setBranchAddressesInBoldToken(
            address(tm), address(sp), address(bo), address(ap)
        );
        vm.stopPrank();
    }

    function test_fixedPriceFeed() public {
        FixedPriceFeed pf = new FixedPriceFeed(5e18);
        (uint256 price, bool down) = pf.fetchPrice();
        assertEq(price, 5e18);
        assertFalse(down);
        assertEq(pf.lastGoodPrice(), 5e18);
    }

    function test_deployAndRegisterBranch() public {
        uint256 branchesBefore = registry.branches();
        _deployBranch();
        _executeGovernance();
        assertEq(registry.branches(), branchesBefore + 1);
    }

    function test_fullFlow_mintMUST() public {
        _deployBranch();
        _executeGovernance();

        address minter = makeAddr("minter");

        // Mint 1M savior tokens ($5M collateral)
        address saviorOwner = saviorToken.owner();
        uint256 collAmount = 1_000_000e18;
        vm.prank(saviorOwner);
        saviorToken.mint(minter, collAmount);

        // Give minter WETH for gas compensation
        deal(WETH, minter, 1 ether);

        vm.startPrank(minter);
        saviorToken.approve(address(bo), collAmount);
        IERC20(WETH).approve(address(bo), 1 ether);

        bo.openTrove(
            minter, 0, collAmount, 2_000_000e18,
            0, 0, 0.05e18, type(uint256).max,
            address(0), address(0), address(0)
        );
        vm.stopPrank();

        uint256 mustBal = IERC20(BOLD_TOKEN).balanceOf(minter);
        assertGe(mustBal, 2_000_000e18);
        console2.log("MUST minted:", mustBal / 1e18);
    }
}
