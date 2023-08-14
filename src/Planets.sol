// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Planets is ERC721, Ownable {
    uint256 public currentTokenId;

    // equivalent $RTS
    // ER = Equivalent Rates
    uint public totalERSupply;
    uint8 public decimals;
    uint public tokensMinted;
    uint public rewardEra;
    uint public maxSupplyForEra;
    uint public miningTarget;
    uint public latestDifficultyPeriodStarted;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function mintTo(address recipient) public payable returns (uint256) {
        uint256 newItemId = ++currentTokenId;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }
}
