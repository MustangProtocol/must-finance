// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {WrappedTokenZapper} from "src/Zappers/WrappedTokenZapper.sol";
import {IAddressesRegistry} from "src/Interfaces/IAddressesRegistry.sol";
import {IFlashLoanProvider} from "src/Zappers/Interfaces/IFlashLoanProvider.sol";
import {IExchange} from "src/Zappers/Interfaces/IExchange.sol";
import {IWrappedToken} from "src/Interfaces/IWrappedToken.sol";

contract DeployWrappedTokenZapper is Script {
    function run() external {
        vm.startBroadcast();
        
        // address SAGA_TOKEN_ADDRESS = 0xA19377761FED745723B90993988E04d641c2CfFE;
        IWrappedToken wSagaToken = IWrappedToken(0x62bEeEf5F6C0a84C508e6B8690bE9ea04ECffCB3);
        IAddressesRegistry addressesRegistry = IAddressesRegistry(0x2A14AbE6A3FC35aFF513Cf0bFd26C84cdD545371);
        IFlashLoanProvider flashLoanProvider = IFlashLoanProvider(0x0000000000000000000000000000000000000000);
        IExchange hybridExchange = IExchange(0x0000000000000000000000000000000000000000);

        WrappedTokenZapper newWrappedTokenZapper = new WrappedTokenZapper(wSagaToken, addressesRegistry, flashLoanProvider, hybridExchange);

        console.log("newWrappedTokenZapper: ", address(newWrappedTokenZapper));
    }
}
