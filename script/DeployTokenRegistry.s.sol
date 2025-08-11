// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {TokenRegistry} from "lib/hyper-evm-lib/src/registry/TokenRegistry.sol";

contract DeployTokenRegistry is Script {
    function run() external {
        
        vm.createSelectFork("hyperevm");

        vm.startBroadcast();

        // deploy read contract
        TokenRegistry tokenRegistry = new TokenRegistry();
        console2.log("TokenRegistry contract deployed on HyperEVM to: ", address(tokenRegistry));

        vm.stopBroadcast();
    }
}
