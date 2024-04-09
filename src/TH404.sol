//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC404.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TopHat404 is ERC404 {
    string public baseTokenURI =
        "https://ipfs.io/ipfs/QmVjZW1f4X1nibQeBWQkg5yEfcZdg8CJ73mHwDMbx93CoX";

    constructor(address _owner) ERC404("TOP HAT 404", "TH", 18, 10000, _owner) {
        balanceOf[_owner] = 10000 * 10 ** 18;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI);
    }
}
