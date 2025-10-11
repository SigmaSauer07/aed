// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Base64 {
    bytes private constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) {
            return "";
        }

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        bytes memory table = TABLE;

        uint256 dataIndex;
        uint256 resultIndex;

        for (; dataIndex + 3 <= data.length; dataIndex += 3) {
            (result[resultIndex], result[resultIndex + 1], result[resultIndex + 2], result[resultIndex + 3]) = _encode3(
                uint8(data[dataIndex]),
                uint8(data[dataIndex + 1]),
                uint8(data[dataIndex + 2]),
                table
            );
            resultIndex += 4;
        }

        if (dataIndex + 2 == data.length) {
            (result[resultIndex], result[resultIndex + 1], result[resultIndex + 2], result[resultIndex + 3]) = _encode2(
                uint8(data[dataIndex]),
                uint8(data[dataIndex + 1]),
                table
            );
        } else if (dataIndex + 1 == data.length) {
            (result[resultIndex], result[resultIndex + 1], result[resultIndex + 2], result[resultIndex + 3]) = _encode1(
                uint8(data[dataIndex]),
                table
            );
        }

        return string(result);
    }

    function _encode3(uint256 a0, uint256 a1, uint256 a2, bytes memory table)
        private
        pure
        returns (bytes1, bytes1, bytes1, bytes1)
    {
        return (
            table[(a0 >> 2) & 0x3F],
            table[((a0 << 4) | (a1 >> 4)) & 0x3F],
            table[((a1 << 2) | (a2 >> 6)) & 0x3F],
            table[a2 & 0x3F]
        );
    }

    function _encode2(uint256 a0, uint256 a1, bytes memory table)
        private
        pure
        returns (bytes1, bytes1, bytes1, bytes1)
    {
        return (
            table[(a0 >> 2) & 0x3F],
            table[((a0 << 4) | (a1 >> 4)) & 0x3F],
            table[(a1 << 2) & 0x3F],
            "="
        );
    }

    function _encode1(uint256 a0, bytes memory table)
        private
        pure
        returns (bytes1, bytes1, bytes1, bytes1)
    {
        return (
            table[(a0 >> 2) & 0x3F],
            table[(a0 << 4) & 0x3F],
            "=",
            "="
        );
    }
}
