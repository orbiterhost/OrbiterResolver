// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {OrbiterResolver} from "../src/OrbiterResolver.sol";
import "../lib/ens-contracts/contracts/registry/ENS.sol";
import "../lib/ens-contracts/contracts/wrapper/INameWrapper.sol";
import "../lib/ens-contracts/contracts/registry/ENSRegistry.sol";

contract OrbiterResolverTest is Test {
    OrbiterResolver public resolver;
    ENS public ens;
    INameWrapper public nameWrapper;

    address signer = address(0x123);
    address owner = address(0x456);
    string url = "https://example.com";

    function setUp() public {
        ens = new ENSRegistry(); // Use concrete implementation instead of interface
        nameWrapper = INameWrapper(address(0x789)); // Mock wrapper
        resolver = new OrbiterResolver(ens, nameWrapper, url, signer, owner);
    }

    function testSetUrl() public {
        string memory newUrl = "https://newexample.com";
        vm.prank(owner);
        resolver.setUrl(newUrl);
        assertEq(resolver.url(), newUrl);
    }

    function testSetSigner() public {
        address newSigner = address(0xabc);
        vm.prank(owner);
        resolver.setSigner(newSigner);
        assertEq(resolver.signer(), newSigner);
    }

    // function testOnlyOwnerCanSetUrl() public {
    //     string memory newUrl = "https://newexample.com";
    //     vm.prank(address(0xdef));
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     resolver.setUrl(newUrl);
    // }

    // function testOnlyOwnerCanSetSigner() public {
    //     address newSigner = address(0xabc);
    //     vm.prank(address(0xdef));
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     resolver.setSigner(newSigner);
    // }
}
