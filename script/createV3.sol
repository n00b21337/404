// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "./interfaces/uniswap_v3.sol";

contract Execute is Script {
    function run()
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // List of factories https://github.com/Uniswap/sdk-core/blob/5365ae4cd021ab53b94b0879ec6ceb6ad3ebdce9/src/addresses.ts#L135
        // Code per https://solidity-by-example.org/defi/uniswap-v3-liquidity/

        address WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // change me!  WETH
        address newToken = 0xFbdc80810255998549A301959A4F0D3beBFC89fB; // change me!
        address nfpm = 0x1238536071E1c677A632429e3655c799b22cDA52; // change me!
        uint24 fee = 3000;

        IERC20 newtoken = IERC20(newToken);
        IWETH weth = IWETH(WETH);
        int24 MIN_TICK = -887272;
        int24 MAX_TICK = -MIN_TICK;
        int24 TICK_SPACING = 60;
        uint256 amountToAddNewToken = 10000;
        uint256 amountToAddWETH = 1;

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nfpm
            );

        newtoken.approve(
            address(nonfungiblePositionManager),
            amountToAddNewToken
        );
        weth.approve(address(nonfungiblePositionManager), amountToAddWETH);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: newToken,
                token1: WETH,
                fee: fee,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amountToAddNewToken,
                amount1Desired: amountToAddWETH,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        vm.stopBroadcast();
    }
}
