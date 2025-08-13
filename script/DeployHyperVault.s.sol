// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {HyperVault} from "../src/HyperVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployHyperVault is Script {
    function run() external {

        address HLP_VAULT;
        ERC20 depositToken;

        string memory network = vm.envString("NETWORK");

        if (keccak256(bytes(network)) == keccak256(bytes("testnet"))) {
            HLP_VAULT = 0xa15099a30BBf2e68942d6F4c43d70D04FAEab0A0;
            depositToken = ERC20(0xd9CBEC81df392A88AEff575E962d149d57F4d6bc);
        } else if (keccak256(bytes(network)) == keccak256(bytes("mainnet"))) {
            HLP_VAULT = 0xdfc24b077bc1425AD1DEA75bCB6f8158E10Df303;
            depositToken = ERC20(0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb);
        } else {
            revert("Unknown network");
        }
        
        vm.createSelectFork(network);

        vm.startBroadcast();

        // deploy read contract
        HyperVault hyperVault = new HyperVault(HLP_VAULT, depositToken, "hypervaultUSDC", "hvUSDC");
        console2.log("HyperVault contract deployed on HyperEVM to: ", address(hyperVault));

        vm.stopBroadcast();
    }
}
