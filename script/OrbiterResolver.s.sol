// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {OrbiterResolver} from "../src/OrbiterResolver.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {INameWrapper} from "../lib/ens-contracts/contracts/wrapper/INameWrapper.sol";

contract DeployResolver is Script {
    OrbiterResolver public resolver;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ENS ens = ENS(vm.envAddress("ENS_REGISTRY"));
        INameWrapper nameWrapper = INameWrapper(vm.envAddress("NAME_WRAPPER"));
        string memory url = vm.envString("GATEWAY_URL");
        address signer = vm.envAddress("SIGNER");
        address owner = vm.envAddress("OWNER");
        address publicResolver = vm.envAddress("PUBLIC_RESOLVER");
        address legacyResolver = vm.envAddress("LEGACY_RESOLVER");

        resolver = new OrbiterResolver(
            ens,
            nameWrapper,
            url,
            signer,
            owner,
            publicResolver,
            legacyResolver
        );

        vm.stopBroadcast();
    }
}
