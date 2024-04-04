// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../script/libraries/TickMath.sol";

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
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
}

contract Meme is ERC20, Ownable {
    INonfungiblePositionManager nfpm;
    address immutable weth;
    uint supply = 1_000_000 * 10 ** decimals();
    uint supplyWeth = 1 * 10 ** decimals();
    uint24 constant fee = 3000;
    uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(-887272);
    int24 MIN_TICK = -887272;
    int24 MAX_TICK = 887272;
    int24 TICK_SPACING = 60;
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;
    uint public LPtokenID;

    constructor(
        address _nfpm,
        address _weth,
        address _owner,
        string memory _name,
        string memory _ticker
    ) ERC20(_name, _ticker) Ownable(_owner) {
        nfpm = INonfungiblePositionManager(_nfpm);
        weth = _weth;
        _mint(address(this), supply);
        // TODO should also probably set sqrtPriceX96 depending on which token is first
        setTokens();
        pool = nfpm.createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            sqrtPriceX96
        );
    }

    function addLiquidity() public {
        // We put all the token supply here and 0 or some WETH
        // TODO Need to send some weth to the contract first, maybe this all is easier to do with local wallet
        IERC20(address(this)).approve(address(nfpm), supply);
        IERC20(address(weth)).approve(address(nfpm), supplyWeth);

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
    }

    function setTokens() private {
        // Change ordering of tokens so that token0 is smaller hex
        if (address(this) < weth) {
            token0 = address(this);
            token1 = address(weth);
            amount0Desired = supply;
            amount1Desired = supplyWeth;
            sqrtPriceX96 = (1000000 / 1) * 2 ** 96;
            minTick = (MIN_TICK / TICK_SPACING) * TICK_SPACING;
            maxTick = (MAX_TICK / TICK_SPACING) * TICK_SPACING;
        } else {
            token0 = address(weth);
            token1 = address(this);
            amount0Desired = supplyWeth;
            amount1Desired = supply;
            sqrtPriceX96 = uint160(1 * 2 ** 96) / 1e6;
            minTick = (MIN_TICK / TICK_SPACING) * TICK_SPACING;
            maxTick = (MAX_TICK / TICK_SPACING) * TICK_SPACING;
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

    function burnLP() public onlyOwner {
        // We must approve the sender to be able to call burn
        IERC721(address(nfpm)).approve(msg.sender, LPtokenID);
        IERC721(address(nfpm)).safeTransferFrom(
            address(this),
            0x000000000000000000000000000000000000dEaD,
            LPtokenID
        );
    }
}
