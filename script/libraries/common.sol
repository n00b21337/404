// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Common {
    function bytesToAddress(
        bytes memory bys
    ) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function uintToString(uint256 _value) public pure returns (string memory) {
        // If the value is 0, return "0" directly
        if (_value == 0) {
            return "0";
        }

        uint256 temp = _value;
        uint256 digits;

        // Count the number of digits in the value
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Allocate a string of the necessary length
        bytes memory buffer = new bytes(digits);

        // Fill the string from right to left
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (_value % 10)));
            _value /= 10;
        }

        // Convert the bytes array to a string
        return string(buffer);
    }
}
