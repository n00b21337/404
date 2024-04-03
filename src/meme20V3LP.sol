// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bytes4);
}

contract Meme is ERC20 {
    INonfungiblePositionManager nfpm;
    address immutable weth;
    uint supply = 1_000_000 * 10 ** decimals();
    uint24 constant fee = 3000;
    uint160 constant sqrtPriceX96 = 79228162514264337593543950336; // ~ 1:1
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;

    constructor(address _nfpm, address _weth) ERC20("Meme Token", "MEME") {
        nfpm = INonfungiblePositionManager(_nfpm);
        weth = _weth;
        _mint(address(this), supply);
        setTokens();
        pool = nfpm.createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            sqrtPriceX96
        );
    }

    function addLiquidity() public {
        // We put all the supply here and 0 WETH
        IERC20(address(this)).approve(address(nfpm), supply);
        nfpm.mint(
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
                recipient: address(0), // We send NFT to 0 address so that liquidity is burned
                deadline: block.timestamp + 1200
            })
        );
    }

    function setTokens() private {
        // Change ordering of tokens so that token0 is smaller hex
        if (address(this) < weth) {
            token0 = address(this);
            token1 = weth;
            amount0Desired = supply;
            amount1Desired = 0;
            minTick = 0;
            maxTick = 887270;
        } else {
            token0 = weth;
            token1 = address(this);
            amount0Desired = 0;
            amount1Desired = supply;
            minTick = -887270;
            maxTick = 0;
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
