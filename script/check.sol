// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

interface ITH404 {
    function owner() external returns (address);

    function symbol() external returns (string memory);

    function setTokenURI(string memory) external;
}

contract Execute is Script {
    function run() external {
        //  vm.startBroadcast();
        //ITH404 th = ITH404(vm.envAddress("CONTRACT_ADDY"));
        // string memory symbol = th.symbol();
        // console.logString(symbol);

        string memory root = vm.projectRoot();
        uint256 bid = block.chainid;
        string memory path = string.concat(
            root,
            "/broadcast/deploy20.sol/",
            uintToString(bid),
            "/run-latest.json"
        );

        string memory json = vm.readFile(path);
        bytes memory contractName = stdJson.parseRaw(
            json,
            ".transactions[0].contractName"
        );
        bytes memory contractAddress = stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
        );
        bytes memory transactionHash = stdJson.parseRaw(
            json,
            ".receipts[0].transactionHash"
        );

        console.log(string(contractName));
        console.logAddress(bytesToAddress(contractAddress));
        console.logBytes(transactionHash);
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
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
