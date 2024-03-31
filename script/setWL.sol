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
    function createPool(
        address,
        address,
        uint24
    ) external returns (address pool);
}

contract Execute is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ITH404 th = ITH404(vm.envAddress("CONTRACT_ADDY"));

        // WL owner of contract
        th.setWhitelist(msg.sender, true);

        // Prepare to make Uniswap v2/v3 factory address
        // List of factories https://github.com/Uniswap/sdk-core/blob/5365ae4cd021ab53b94b0879ec6ceb6ad3ebdce9/src/addresses.ts#L135

        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // change me!
        address token0 = 0x9E9FbDE7C7a83c43913BddC8779158F1368F0413; // change me!
        address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // change me!
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
        address pairV3 = v3.createPool(token0, token1, fee);
        th.setWhitelist(pairV3, true);

        vm.stopBroadcast();
    }
}
