// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {HyperVault} from "../src/HyperVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployHyperVault is Script {
    function run() external {

        // address HLP_VAULT = address(0xa15099a30BBf2e68942d6F4c43d70D04FAEab0A0); // HyperCore HLP Vault Address
        // ERC20 usdc_testnet = ERC20(0xd9CBEC81df392A88AEff575E962d149d57F4d6bc); // HyperEVM Testnet USDC Address
        
        // vm.createSelectFork("hyperevm");

        address HLP_VAULT = address(0xdfc24b077bc1425AD1DEA75bCB6f8158E10Df303); // HyperCore HLP Vault Address
        ERC20 usdt = ERC20(0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb); // HyperEVM Testnet *USDT* Address
        
        vm.createSelectFork("hyperevm-mainnet");

        vm.startBroadcast();

        // deploy read contract
        HyperVault hyperVault = new HyperVault(HLP_VAULT, usdt, "hypervaultUSDC", "hvUSDC");
        console2.log("HyperVault contract deployed on HyperEVM to: ", address(hyperVault));

        vm.stopBroadcast();
    }
}
