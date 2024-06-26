// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Meme} from "../src/meme20.sol";
import {console} from "forge-std/console.sol";
import "./libraries/common.sol";

contract DeployOurToken is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;
    address public nfpm;
    address public weth;
    uint256 public constant TOKEN_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places

    function run() external returns (Meme) {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else if (block.chainid == 8453) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
            weth = 0x4200000000000000000000000000000000000006;
        } else if (block.chainid == 11155111) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = 0x1238536071E1c677A632429e3655c799b22cDA52;
            weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        } else if (block.chainid == 1) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            weth = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        }

        vm.startBroadcast(deployerKey);
        string memory name = string.concat(
            "Meme Token ",
            Common.uintToString(vm.getNonce(msg.sender))
        );
        string memory ticker = string.concat(
            "MEME ",
            Common.uintToString(vm.getNonce(msg.sender))
        );

        Meme deployedToken = new Meme(name, ticker, TOKEN_SUPPLY);
        console.log("Meme ", vm.getNonce(msg.sender));
        vm.stopBroadcast();
        return deployedToken;
    }
}
