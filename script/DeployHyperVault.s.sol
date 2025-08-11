// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {HyperVault} from "../src/HyperVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployHyperVault is Script {
    function run() external {

        address HLP_VAULT = address(0xa15099a30BBf2e68942d6F4c43d70D04FAEab0A0);
        ERC20 usdc_testnet = ERC20(0xd9CBEC81df392A88AEff575E962d149d57F4d6bc);
        
        vm.createSelectFork("hyperevm");

        vm.startBroadcast();

        // deploy read contract
        HyperVault hyperVault = new HyperVault(HLP_VAULT, usdc_testnet, "hypervaultUSDC", "hvUSDC");
        console2.log("HyperVault contract deployed on HyperEVM to: ", address(hyperVault));

        vm.stopBroadcast();
    }
}
