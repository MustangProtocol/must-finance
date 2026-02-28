// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../src/Interfaces/ICollateralRegistry.sol";
import "../src/Interfaces/IAddressesRegistry.sol";
import "../src/Interfaces/IPriceFeed.sol";
import "../src/Interfaces/IBoldToken.sol";
import "../src/AddressesRegistry.sol";
import "../src/BorrowerOperations.sol";
import "../src/TroveManager.sol";
import "../src/TroveNFT.sol";
import "../src/StabilityPool.sol";
import "../src/ActivePool.sol";
import "../src/DefaultPool.sol";
import "../src/GasPool.sol";
import "../src/CollSurplusPool.sol";
import "../src/SortedTroves.sol";
import {IMetadataNFT} from "../src/NFTMetadata/MetadataNFT.sol";

// Mintable ERC20
contract SaviorToken is ERC20 {
    address public owner;
    constructor() ERC20("Savior Token", "SAVIOR") { owner = msg.sender; }
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "only owner");
        _mint(to, amount);
    }
}

// Always returns a fixed price
contract FixedPriceFeed is IPriceFeed {
    uint256 public lastGoodPrice;
    constructor(uint256 _price) { lastGoodPrice = _price; }
    function fetchPrice() external view returns (uint256, bool) { return (lastGoodPrice, false); }
    function fetchRedemptionPrice() external view returns (uint256, bool) { return (lastGoodPrice, false); }
}

// Dummy — just satisfies the interface so TroveNFT deploys
contract DummyMetadataNFT is IMetadataNFT {
    function uri(TroveData memory) external pure returns (string memory) { return ""; }
}

// ============================================================
//  ENV VARS:
//    COLLATERAL_REGISTRY, HINT_HELPERS, MULTI_TROVE_GETTER,
//    BOLD_TOKEN, WETH, GOVERNANCE, SAVIOR_PRICE, SAVIOR_MINT_AMOUNT
//
//  forge script script/DeploySaviorBranch.s.sol:DeploySaviorBranch \
//    --rpc-url $RPC_URL --broadcast --account cast-wallet -vvvv
// ============================================================
contract DeploySaviorBranch is Script {
    bytes32 constant SALT = keccak256("savior");

    struct Cfg {
        address collReg;
        address hints;
        address mtg;
        address bold;
        address weth;
        address gov;
        uint256 price;
        uint256 mintAmt;
    }

    function run() external {
        Cfg memory c = Cfg({
            collReg:  vm.envAddress("COLLATERAL_REGISTRY"),
            hints:    vm.envAddress("HINT_HELPERS"),
            mtg:      vm.envAddress("MULTI_TROVE_GETTER"),
            bold:     vm.envAddress("BOLD_TOKEN"),
            weth:     vm.envAddress("WETH"),
            gov:      vm.envAddress("GOVERNANCE"),
            price:    vm.envUint("SAVIOR_PRICE"),
            mintAmt:  vm.envUint("SAVIOR_MINT_AMOUNT")
        });

        uint256 branchId = _branches(c.collReg);
        console2.log("Branch ID:", branchId);

        vm.startBroadcast();
        _deploy(c, branchId);
        vm.stopBroadcast();
    }

    function _branches(address reg) internal view returns (uint256) {
        (bool ok, bytes memory d) = reg.staticcall(abi.encodeWithSignature("branches()"));
        require(ok);
        return abi.decode(d, (uint256));
    }

    function _deploy(Cfg memory c, uint256 branchId) internal {
        // 1. Token + price feed + dummy metadata
        SaviorToken token = new SaviorToken();
        FixedPriceFeed feed = new FixedPriceFeed(c.price);
        DummyMetadataNFT meta = new DummyMetadataNFT();

        // 2. AddressesRegistry — loose params, unlimited debt
        AddressesRegistry ar = new AddressesRegistry(
            msg.sender, 15e17, 11e17, 10e16, 105e16,
            type(uint256).max, 5e16, 10e16
        );
        IAddressesRegistry iReg = IAddressesRegistry(address(ar));
        address reg = address(ar);

        // 3. Wire addresses (pre-compute CREATE2 addrs)
        IAddressesRegistry.AddressVars memory v;
        v.collToken          = IERC20Metadata(address(token));
        v.borrowerOperations = IBorrowerOperations(_c2(type(BorrowerOperations).creationCode, reg));
        v.troveManager       = ITroveManager(_c2x(type(TroveManager).creationCode, reg, branchId));
        v.troveNFT           = ITroveNFT(_c2(type(TroveNFT).creationCode, reg));
        v.metadataNFT        = IMetadataNFT(address(meta));
        v.stabilityPool      = IStabilityPool(_c2(type(StabilityPool).creationCode, reg));
        v.priceFeed          = IPriceFeed(address(feed));
        v.activePool         = IActivePool(_c2(type(ActivePool).creationCode, reg));
        v.defaultPool        = IDefaultPool(_c2(type(DefaultPool).creationCode, reg));
        v.gasPoolAddress     = _c2(type(GasPool).creationCode, reg);
        v.collSurplusPool    = ICollSurplusPool(_c2(type(CollSurplusPool).creationCode, reg));
        v.sortedTroves       = ISortedTroves(_c2(type(SortedTroves).creationCode, reg));
        v.interestRouter     = IInterestRouter(c.gov);
        v.hintHelpers        = IHintHelpers(c.hints);
        v.multiTroveGetter   = IMultiTroveGetter(c.mtg);
        v.collateralRegistry = ICollateralRegistry(c.collReg);
        v.boldToken          = IBoldToken(c.bold);
        v.WETH               = IWETH(c.weth);

        ar.setAddresses(v); // renounces ownership

        // 4. Deploy branch contracts
        new BorrowerOperations{salt: SALT}(iReg);
        TroveManager tm = new TroveManager{salt: SALT}(iReg, branchId);
        new TroveNFT{salt: SALT}(iReg);
        new StabilityPool{salt: SALT}(iReg);
        new ActivePool{salt: SALT}(iReg);
        new DefaultPool{salt: SALT}(iReg);
        new GasPool{salt: SALT}(iReg);
        new CollSurplusPool{salt: SALT}(iReg);
        new SortedTroves{salt: SALT}(iReg);

        // 5. Register + mint
        ICollateralRegistry(c.collReg).addCollateral(IERC20Metadata(address(token)), tm);
        token.mint(msg.sender, c.mintAmt);

        console2.log("SaviorToken:", address(token));
        console2.log("TroveManager:", address(tm));
        console2.log("Done. Mint unbacked debt, redeem to rescue.");
    }

    function _c2(bytes memory code, address a) internal view returns (address) {
        return vm.computeCreate2Address(SALT, keccak256(abi.encodePacked(code, abi.encode(a))));
    }
    function _c2x(bytes memory code, address a, uint256 b) internal view returns (address) {
        return vm.computeCreate2Address(SALT, keccak256(abi.encodePacked(code, abi.encode(a, b))));
    }
}
