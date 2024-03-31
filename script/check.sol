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
        ITH404 th = ITH404(vm.envAddress("CONTRACT_ADDY"));
        string memory symbol = th.symbol();
        console.logString(symbol);

        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/broadcast/deploy.sol/666666666/run-latest.json"
        );

        console.logString(path);
        // Tx1559[] memory transactions = readTx1559s(path);

        // console.log(transactions[0].contractAddress);
        //   vm.stopBroadcast();

        //return transactions[0];
    }
}
