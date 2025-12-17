
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30

interface IAEDResolver {
    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);
    event ContentHashChanged(bytes32 indexed node, bytes hash);
    event TextChanged(bytes32 indexed node, string indexed key, string value);

    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint256 coinType, bytes calldata addr) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;

    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function text(bytes32 node, string calldata key) external view returns (string memory);

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}
