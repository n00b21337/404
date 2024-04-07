// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Meme is ERC20 {
    uint public supplyTotal;

    constructor(
        string memory _name,
        string memory _ticker,
        uint _supply
    ) ERC20(_name, _ticker) {
        supplyTotal = _supply;
        _mint(msg.sender, _supply);
    }
}
