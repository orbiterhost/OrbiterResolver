// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/ens-contracts/contracts/registry/ENS.sol";
import "../lib/ens-contracts/contracts/wrapper/INameWrapper.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";
import "../lib/ens-contracts/contracts/resolvers/Multicallable.sol";
import "../lib/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./SignatureVerifier.sol";

interface IResolverService {
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        returns (bytes memory result, uint64 expires, bytes memory sig);
}

/**
 * A hybrid onchain/offchain ENS resolver contract for flexible record management.
 */
contract OrbiterResolver is
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    InterfaceResolver,
    NameResolver,
    TextResolver,
    IExtendedResolver,
    Ownable
{
    ENS immutable ens;
    INameWrapper immutable nameWrapper;
    string public url;
    address public signer;

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    constructor(ENS _ens, INameWrapper _nameWrapper, string memory _url, address _signer, address _owner)
        Ownable(_owner)
    {
        ens = _ens;
        nameWrapper = _nameWrapper;
        url = _url;
        signer = _signer;
    }

    function resolve(bytes calldata name, bytes memory data) external view virtual returns (bytes memory) {
        (bool success, bytes memory result) = address(this).staticcall(data);
        bytes32 hashedResult = keccak256(result);

        // keccak256(0x0000000000000000000000000000000000000000000000000000000000000000)
        // covers empty addr(node), name(node), contenthash(node)
        bytes32 emptySingleArg = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

        // keccak256(0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000)
        // covers addr(node, coinType), text(node, key), ABI(node, contentTypes)
        bytes32 emptyDoubleArg = 0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd;

        if (success && (hashedResult != emptySingleArg) && (hashedResult != emptyDoubleArg)) {
            // If we have an onchain result, return it
            return result;
        } else {
            // Otherwise, fallback to offchain lookup
            return resolveOffchain(name, data);
        }
    }

    function resolveOffchain(bytes calldata name, bytes memory data) internal view virtual returns (bytes memory) {
        bytes memory callData = abi.encodeWithSelector(IResolverService.resolve.selector, name, data);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(
            address(this),
            urls,
            callData,
            OrbiterResolver.resolveWithProof.selector,
            abi.encode(callData, address(this))
        );
    }

    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
        (address _signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
        require(_signer == signer, "SignatureVerifier: Invalid sigature");
        return result;
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            Multicallable, ABIResolver, AddrResolver, ContentHashResolver, InterfaceResolver, NameResolver, TextResolver
        )
        returns (bool)
    {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        address owner = ens.owner(node);

        if (
            owner == address(nameWrapper)
                ? !nameWrapper.canModifyName(node, msg.sender)
                : (owner != msg.sender && !ens.isApprovedForAll(owner, msg.sender))
        ) {
            return false;
        }

        return true;
    }

    function setUrl(string memory _url) external onlyOwner {
        url = _url;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}
