// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITH404 {
    function owner() external;

    function symbol() external;

    function setTokenURI(string memory) external;
}

contract CheckScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ITH404 th = ITH404(0xc5D38Bcc8E0B8a7C61bef5b1cc8945118a0Fd712);

        th.setTokenURI(
            "https://ipfs.io/ipfs/QmVjZW1f4X1nibQeBWQkg5yEfcZdg8CJ73mHwDMbx93CoX"
        );

        // console.logString("ssss");
        vm.stopBroadcast();
        return th.symbol();
    }
}
