// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SqrtPricex96 {
    uint256 constant Q96 = 2 ** 96;

    function calculateSqrtPriceX96(
        uint256 tokenAmount,
        uint256 wethAmount
    ) public pure returns (uint160 sqrtPriceX96) {
        // Ensure non-zero values to prevent division by zero
        require(
            tokenAmount > 0 && wethAmount > 0,
            "Amounts must be greater than zero"
        );

        // First, multiply wethAmount by Q96^2 to scale it up before division
        // Then, divide by tokenAmount and finally calculate the square root
        // The multiplication by Q96^2 is done first to avoid loss of precision before the division
        uint256 scaledWethAmount = wethAmount * Q96 ** 2;
        uint256 priceRatio = scaledWethAmount / tokenAmount;

        // Now compute the square root
        sqrtPriceX96 = uint160(sqrt(priceRatio));
    }

    // Basic integer square root function
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        } else {
            z = 0;
        }
        return z;
    }

    // This function is to illustrate how you would reverse the calculation to find the price
    function calculatePriceFromSqrtPriceX96(
        uint256 sqrtPriceX96
    ) public pure returns (uint256 price) {
        uint256 squaredPrice = uint256(sqrtPriceX96) ** 2;
        uint256 scaledPrice = squaredPrice / Q96 ** 2;

        price = uint160(scaledPrice);
    }
}
