// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "./interfaces/uniswap_v3.sol";
import "./libraries/sqrtPricex96.sol";

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
        // UNI v3 error codes https://github.com/Uniswap/docs/blob/7d22be080cafa773b6fb38a238531211b8cade00/docs/contracts/v3/reference/error-codes.md?plain=1#L36

        address WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // change me!  WETH
        address newToken = 0xFbdc80810255998549A301959A4F0D3beBFC89fB; // change me!
        address nfpm = 0x1238536071E1c677A632429e3655c799b22cDA52; // change me!
        uint24 fee = 3000; // 100 is 0.01%, 500 is 0.05%, 3000 is 0.3%, 10000 is 1%

        IERC20 newtoken = IERC20(newToken);
        IWETH weth = IWETH(WETH);
        int24 MIN_TICK = -887220;
        int24 MAX_TICK = -MIN_TICK;
        int24 TICK_SPACING = 60; // 10 for 500, 60 for 3000 and 200 for 10000, needs to match fee, meaning to be divisible by fee https://github.com/Uniswap/v3-core/blob/d8b1c635c275d2a9450bd6a78f3fa2484fef73eb/contracts/UniswapV3Factory.sol#L26
        uint256 amountToAddNewToken = 10000;
        uint256 amountToAddWETH = 1;

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nfpm
            );

        uint160 sqrtPriceX96 = SqrtPricex96.calculateSqrtPriceX96(1000, 1);
        console.log(sqrtPriceX96);

        // We need to create and initialize pool https://docs.uniswap.org/contracts/v3/reference/periphery/base/PoolInitializer
        // sqrtPriceX96 is directly calling https://github.com/Uniswap/v3-core/blob/d8b1c635c275d2a9450bd6a78f3fa2484fef73eb/contracts/libraries/TickMath.sol#L61C14-L61C32
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            WETH,
            newToken,
            fee,
            sqrtPriceX96
        );

        newtoken.approve(
            address(nonfungiblePositionManager),
            amountToAddNewToken
        );
        weth.approve(address(nonfungiblePositionManager), amountToAddWETH);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: WETH,
                token1: newToken,
                fee: fee,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amountToAddWETH,
                amount1Desired: amountToAddNewToken,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 60 * 20
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        vm.stopBroadcast();
    }
}
