// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Meme} from "../src/meme20.sol";
import {console} from "forge-std/console.sol";
import "./libraries/TickMath.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "./libraries/common.sol";

interface IERC20 {
    function approve(address to, uint256 amount) external;
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

contract InitPairDeployLiquidity is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    // Set valus for pool
    uint256 public constant WETH_SUPPLY = 1 ether; // 1 tokens with 18 decimal places
    uint256 public constant TOKEN_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places
    int24 MIN_TICK = -887272;
    int24 MAX_TICK = 887272;
    uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(-13787);

    uint24 fee = 3000;
    int24 TICK_SPACING = 60;
    int24 minTick = (MIN_TICK / TICK_SPACING) * TICK_SPACING;
    int24 maxTick = (MAX_TICK / TICK_SPACING) * TICK_SPACING;

    address public weth;
    address public deployedAddress;
    Meme deployedMeme;
    INonfungiblePositionManager nfpm;

    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;
    uint public LPtokenID;

    function fetchLatest() public {
        string memory root = vm.projectRoot();
        uint256 bid = block.chainid;
        string memory path = string.concat(
            root,
            "/broadcast/deploy20.sol/",
            Common.uintToString(bid),
            "/run-latest.json"
        );

        string memory json = vm.readFile(path);

        // Contract name will be saved only if -vvvv was used
        bytes memory contractName = stdJson.parseRaw(
            json,
            ".transactions[0].contractName"
        );
        bytes memory contractAddress = stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
        );

        // bytes memory transactionHash = stdJson.parseRaw(
        //     json,
        //     ".receipts[0].transactionHash"
        // );

        // Set current latest deployed meme address
        deployedAddress = Common.bytesToAddress(contractAddress);
    }

    function reorderTokens() private {
        // Change ordering of tokens so that token0 is smaller hex
        if (address(this) < weth) {
            token0 = address(deployedAddress);
            token1 = address(weth);
            amount0Desired = TOKEN_SUPPLY;
            amount1Desired = WETH_SUPPLY;
        } else {
            token0 = address(weth);
            token1 = address(deployedAddress);
            amount0Desired = WETH_SUPPLY;
            amount1Desired = TOKEN_SUPPLY;
        }
    }

    function run() external returns (Meme) {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else if (block.chainid == 8453) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = INonfungiblePositionManager(
                0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1
            );
            weth = 0x4200000000000000000000000000000000000006;
        } else if (block.chainid == 11155111) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = INonfungiblePositionManager(
                0x1238536071E1c677A632429e3655c799b22cDA52
            );
            weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        } else if (block.chainid == 1) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            nfpm = INonfungiblePositionManager(
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            );
            weth = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        }

        vm.startBroadcast(deployerKey);
        uint nonceForToken = vm.getNonce(msg.sender);

        // Fetch latest deployed Meme token from deploy20.sol
        fetchLatest();
        deployedMeme = Meme(deployedAddress);
        console.log(deployedAddress);

        // Approve token and weth from EOA to be used by nfpm
        IERC20(address(deployedAddress)).approve(address(nfpm), TOKEN_SUPPLY);
        IERC20(address(weth)).approve(address(nfpm), WETH_SUPPLY);

        // Init pool
        reorderTokens();
        pool = nfpm.createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            sqrtPriceX96
        );

        // TODO should also probably set sqrtPriceX96 depending on which token is first ?
        // Create pool and receive NFT for it
        (LPtokenID, , , ) = nfpm.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 1200
            })
        );

        // We burn LP tokens with NFT sending to dEaD address
        // IERC721(address(nfpm)).safeTransferFrom(
        //     msg.sender,
        //     0x000000000000000000000000000000000000dEaD,
        //     LPtokenID
        // );

        // SQRT for 0 is 79228162514264337593543950336  which is also  2^96 https://docs.uniswap.org/contracts/v4/concepts/managing-positions
        //console.log(TickMath.getSqrtRatioAtTick(0));

        console.log("Deployed Meme ", nonceForToken);
        vm.stopBroadcast();
        return deployedMeme;
    }
}
