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

contract CheckScript is Script {
    function run() external returns (Tx1559 memory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ITH404 th = ITH404(0xc5D38Bcc8E0B8a7C61bef5b1cc8945118a0Fd712);
        string memory symbol = th.symbol();
        console.logString(symbol);

        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/broadcast/deploy.sol/666666666/run-latest.json"
        );

        // Tx1559[] memory transactions = readTx1559s(path);

        // console.log(transactions[0].contractAddress);
        vm.stopBroadcast();

        //return transactions[0];
    }
}
