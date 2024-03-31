// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITH404 {
    function owner() external;

    function symbol() external;

    function setWhitelist(address, bool) external;
}

interface IUniV3 {
    function getPool(address, address, uint24) external returns (address pool);
}

contract Execute is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ITH404 th = ITH404(vm.envAddress("CONTRACT_ADDY"));

        // WL owner of contract
        th.setWhitelist(msg.sender, true);
        console.log("Set WL owner", msg.sender);

        // Prepare to make Uniswap v2/v3 factory address
        // List of factories https://github.com/Uniswap/sdk-core/blob/5365ae4cd021ab53b94b0879ec6ceb6ad3ebdce9/src/addresses.ts#L135

        address factory = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c; // change me!
        address token0 = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // change me!  WETH
        address token1 = 0xFbdc80810255998549A301959A4F0D3beBFC89fB; // change me!
        uint24 fee = 3000;

        //UNI V2 pair
        address pairV2 = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );

        //UNI V3 Pair
        IUniV3 v3 = IUniV3(factory);
        address pairV3 = v3.getPool(token0, token1, fee);
        th.setWhitelist(pairV3, true);
        console.log("Set WL V3 Pair", pairV3);

        vm.stopBroadcast();
    }
}
