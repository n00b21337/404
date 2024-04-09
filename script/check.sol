// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "./libraries/common.sol";

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
            Common.uintToString(bid),
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
        console.logAddress(Common.bytesToAddress(contractAddress));
        console.logBytes(transactionHash);
    }
}
