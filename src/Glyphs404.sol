//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC404.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Glyphs404 is ERC404 {


    ///////////////////
    //// GENERATOR ////
    ///////////////////

    int constant ONE = int(0x100000000);
    uint constant USIZE = 64;
    int constant SIZE = int(USIZE);
    int constant HALF_SIZE = SIZE / int(2);

    int constant SCALE = int(0x1b81a81ab1a81a823);
    int constant HALF_SCALE = SCALE / int(2);

    bytes prefix = "data:text/plain;charset=utf-8,";

    // 0x2E = .
    // 0x4F = O
    // 0x2B = +
    // 0x58 = X
    // 0x7C = |
    // 0x2D = -
    // 0x5C = \
    // 0x2F = /
    // 0x23 = #

        mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;

    /**
     * @dev A mapping from NFT ID to the seed used to make it.
     */
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;


    constructor(address _owner) ERC404("Glyphs404", "G0G", 18, 10000, _owner) {
        balanceOf[_owner] = 10000 * 10 ** 18;
    }

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }


    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }

    function getScheme(uint a) internal pure returns (uint8) {
        uint index = a % 83;
        uint8 scheme;
        if (index < 20) {
            scheme = 1;
        } else if (index < 35) {
            scheme = 2;
        } else if (index < 48) {
            scheme = 3;
        } else if (index < 59) {
            scheme = 4;
        } else if (index < 68) {
            scheme = 5;
        } else if (index < 73) {
            scheme = 6;
        } else if (index < 77) {
            scheme = 7;
        } else if (index < 80) {
            scheme = 8;
        } else if (index < 82) {
            scheme = 9;
        } else {
            scheme = 10;
        }
        return scheme;
    }

        /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) public override view  returns (string memory) {
        return draw(_tokenId);
    }

        // The following code generates art.

    function draw(uint id) public view returns (string memory) {
        uint a = uint(uint160(uint(keccak256(abi.encodePacked(idToSeed[id])))));

        bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
        uint c;
        for (c = 0; c < 30; c++) {
            output[c] = prefix[c];
        }
        int x = 0;
        int y = 0;
        uint v = 0;
        uint value = 0;
        uint mod = (a % 11) + 5;
        bytes5 symbols;
        if (idToSymbolScheme[id] == 0) {
            revert();
        } else if (idToSymbolScheme[id] == 1) {
            symbols = 0x2E582F5C2E; // X/\
        } else if (idToSymbolScheme[id] == 2) {
            symbols = 0x2E2B2D7C2E; // +-|
        } else if (idToSymbolScheme[id] == 3) {
            symbols = 0x2E2F5C2E2E; // /\
        } else if (idToSymbolScheme[id] == 4) {
            symbols = 0x2E5C7C2D2F; // \|-/
        } else if (idToSymbolScheme[id] == 5) {
            symbols = 0x2E4F7C2D2E; // O|-
        } else if (idToSymbolScheme[id] == 6) {
            symbols = 0x2E5C5C2E2E; // \
        } else if (idToSymbolScheme[id] == 7) {
            symbols = 0x2E237C2D2B; // #|-+
        } else if (idToSymbolScheme[id] == 8) {
            symbols = 0x2E4F4F2E2E; // OO
        } else if (idToSymbolScheme[id] == 9) {
            symbols = 0x2E232E2E2E; // #
        } else {
            symbols = 0x2E234F2E2E; // #O
        }
        for (int i = int(0); i < SIZE; i++) {
            y = (2 * (i - HALF_SIZE) + 1);
            if (a % 3 == 1) {
                y = -y;
            } else if (a % 3 == 2) {
                y = abs(y);
            }
            y = y * int(a);
            for (int j = int(0); j < SIZE; j++) {
                x = (2 * (j - HALF_SIZE) + 1);
                if (a % 2 == 1) {
                    x = abs(x);
                }
                x = x * int(a);
                v = uint(x * y / ONE) % mod;
                if (v < 5) {
                     value = uint256(uint8(symbols[v]));
                } else {
                    value = 0x2E;
                }
                output[c] = bytes1(bytes32(value << 248));
                c++;
            }
            output[c] = bytes1(0x25);
            c++;
            output[c] = bytes1(0x30);
            c++;
            output[c] = bytes1(0x41);
            c++;
        }
        string memory result = string(output);
        return result;
    }


    function _mint(address _to) internal override {
        // New implementation of minting logic
        // This can include a call to the base function if needed
         super._mint(_to);
        uint256 id = minted;  

        uint seed = uint(keccak256(abi.encodePacked(block.prevrandao, msg.sender)));


        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint a = uint(keccak256(abi.encodePacked(seed)));
        idToSymbolScheme[id] = getScheme(a);
    }

}
