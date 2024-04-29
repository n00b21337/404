// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Meme} from "../src/meme20.sol";
import {console} from "forge-std/console.sol";
import "./libraries/tickMath.sol";
import "./libraries/sqrtPricex96.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "./libraries/common.sol";

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IUniswapV2Factory {
    function getPair(
        address token0,
        address token1
    ) external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract InitPairDeployLiquidity is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    // Set valus for pool
    uint256 public constant WETH_SUPPLY = 1e15 wei; //  Denotes 0.001 ether, e18 is 1 ether
    uint256 public constant TOKEN_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places

    // Use proper addresses from used chain https://docs.uniswap.org/contracts/v2/reference/smart-contracts/v2-deployments
    address private FACTORY;
    address private ROUTER;

    address public WETH;
    address public deployedAddress;
    Meme deployedMeme;

    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;
    uint public LPtokenID;

    function run() external returns (Meme) {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else if (block.chainid == 8453) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
            ROUTER = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
            WETH = 0x4200000000000000000000000000000000000006;
        } else if (block.chainid == 11155111) {
            // deployerKey = vm.envUint("PRIVATE_KEY");
            // FACTORY = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
            // ROUTER = 0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24;
            // WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        } else if (block.chainid == 1) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
            ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            WETH = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        }

        vm.startBroadcast(deployerKey);
        uint nonceForToken = vm.getNonce(msg.sender);
        console.log("Deployed Meme ", nonceForToken - 1);

        // Fetch latest deployed Meme token from deploy20.sol
        fetchLatest();
        deployedMeme = Meme(deployedAddress);

        // TODO check about should ETH be first or second or its the same
        // uni.addLiquidity(address(WETH), address(USDT), 1 * 1e18, 3000.05 * 1e6);
        // https://solidity-by-example.org/defi/uniswap-v2-add-remove-liquidity/

        amount0Desired = TOKEN_SUPPLY;
        amount1Desired = WETH_SUPPLY;
        token0 = address(deployedAddress);
        token1 = address(WETH);

        safeApprove(IERC20(token0), ROUTER, amount0Desired);
        safeApprove(IERC20(token1), ROUTER, amount1Desired);

        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IUniswapV2Router(ROUTER).addLiquidity(
                token0,
                token1,
                amount0Desired,
                amount1Desired,
                1,
                1,
                msg.sender,
                block.timestamp + 1200
            );

        vm.stopBroadcast();
        return deployedMeme;
    }

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
        // bytes memory contractName = stdJson.parseRaw(
        //     json,
        //     ".transactions[0].contractName"
        // );
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

    /**
     * @dev The transferFrom function may or may not return a bool.
     * The ERC-20 spec returns a bool, but some tokens don't follow the spec.
     * Need to check if data is empty or true.
     */
    function safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeCall(IERC20.transferFrom, (sender, recipient, amount))
        );
        require(
            success &&
                (returnData.length == 0 || abi.decode(returnData, (bool))),
            "Transfer from fail"
        );
    }

    /**
     * @dev The approve function may or may not return a bool.
     * The ERC-20 spec returns a bool, but some tokens don't follow the spec.
     * Need to check if data is empty or true.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeCall(IERC20.approve, (spender, amount))
        );
        require(
            success &&
                (returnData.length == 0 || abi.decode(returnData, (bool))),
            "Approve fail"
        );
    }
}
