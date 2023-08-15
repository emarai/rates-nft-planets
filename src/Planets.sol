// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./AbstractERC918.sol";

contract Planets is AbstractERC918, ERC721, Ownable {
    uint256 public currentTokenId;
    string public baseUri;

    // equivalent $RTS
    // ER = Equivalent Rates
    uint public totalERSupply;

    // mining proof-of-work, adjustment, difficulty
    mapping(bytes32 => bytes32) _solutionForChallenge;
    uint public epochCount; // == planetminted
    uint public BLOCKS_PER_READJUSTMENT = 1024;
    uint public MINING_RATE_FACTOR = 60; //mint the token 60 times less often than ether
    uint public latestDifficultyPeriodStarted;
    uint public MINIMUM_TARGET_DIFFICULTY = 2 ** 16;
    uint public MAXIMUM_TARGET_DIFFICULTY = 2 ** 245; // TODO: should change to 234?
    uint public TARGET_DIVISOR = 2000;
    uint public QUOTIENT_LIMIT = TARGET_DIVISOR / 2;
    uint public MAX_ADJUSTMENT_PERCENT = 100;

    // mining reward
    uint8 public decimals = 18;
    uint public startingAverageReward = 1000 * 10 ** uint(decimals);
    uint public rewardEra = 0;
    uint public maxSupplyForEra = 1000000000 * 10 ** uint(decimals);
    uint public totalRtsPerEra = 0;

    struct PlanetResource {
        uint256 RTS; // Rates
        // uint256 ARTS; // Animal resource
        // uint256 PRTS; // Plant resource
        // uint256 MRTS; // Mineral resource
    }

    mapping(uint256 => PlanetResource) public planetResources;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) ERC721(_name, _symbol) {
        setBaseUri(_baseUri);
        challengeNumber = blockhash(block.number - 1);
        latestDifficultyPeriodStarted = block.number;
        difficulty = MAXIMUM_TARGET_DIFFICULTY;
    }

    // NFT Functions
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }

    // ERC-918 Functions

    function mint(
        uint256 nonce,
        bytes32 challengeDigest
    ) public virtual override returns (bool success) {
        // CHALLENGE CHECK
        // check digest
        bytes32 digest = _hash(nonce, challengeDigest);

        //  digest must be smaller than difficulty
        if (uint256(digest) > difficulty) revert("Nonce incorrect");

        // only allow for one solution
        bytes32 solution = _solutionForChallenge[challengeNumber];
        if (solution != 0x0) revert("Solution exist");

        _solutionForChallenge[challengeNumber] = digest;

        // REWARD CHECK ($RTS inside minted planet)
        uint averageRtsAmount = _reward();

        uint rts25Percent = (averageRtsAmount * 25) / 100;
        uint minimumRts = averageRtsAmount - rts25Percent;
        uint maximumRts = averageRtsAmount + rts25Percent;

        uint step = (maximumRts - minimumRts) / 100;

        uint256 random = _random() % 100;

        uint rtsForPlanet = minimumRts + (random * step);

        // mint nft
        currentTokenId = ++currentTokenId;
        _safeMint(msg.sender, currentTokenId);

        planetResources[currentTokenId] = PlanetResource({RTS: rtsForPlanet});

        // update challenge
        _newEpoch(rtsForPlanet);
        tokensMinted += rtsForPlanet;

        // TODO: diagnostics
        return true;
    }

    function _hash(
        uint256 nonce,
        bytes32 challengeDigest
    ) internal virtual override returns (bytes32 digest) {
        bytes32 digestResult = keccak256(
            abi.encodePacked(challengeNumber, msg.sender, nonce)
        );
        if (digestResult != challengeDigest) revert("Digest is different");

        return digestResult;
    }

    function checkHash(
        uint256 nonce,
        bytes32 challengeDigest
    ) public returns (bytes32 digest) {
        return _hash(nonce, challengeDigest);
    }

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns (uint) {
        return difficulty;
    }

    function getMiningReward() public view returns (uint) {
        // duplicate: _reward()
        return startingAverageReward / (2 ** rewardEra);
    }

    function getMiningTarget() public view returns (uint) {
        return difficulty;
    }

    function getPlanetMinted() public view returns (uint) {
        return currentTokenId;
    }

    // internal functions from abstract
    function _reward() internal virtual override returns (uint) {
        return startingAverageReward / (2 ** rewardEra);
    }

    function _newEpoch(
        uint256 rtsMinted
    ) internal virtual override returns (uint) {
        // decrease planet $RTS every 1 million $RTS minted (planet-wise)
        if ((tokensMinted + rtsMinted) > maxSupplyForEra) {
            rewardEra = rewardEra + 1;
        }
        epochCount = ++epochCount;

        // adjust difficulty every 1024 blocks
        if (epochCount % BLOCKS_PER_READJUSTMENT == 0) {
            _adjustDifficulty();
        }

        challengeNumber = blockhash(block.number - 1);

        return epochCount;
    }

    function _adjustDifficulty() internal virtual override returns (uint) {
        if (epochCount % BLOCKS_PER_READJUSTMENT != 0) {
            return difficulty;
        }

        uint ethBlocksSinceLastDifficultyPeriod = block.number -
            latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour
        //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
        uint epochsMined = BLOCKS_PER_READJUSTMENT;
        uint targetEthBlocksPerDiffPeriod = epochsMined * MINING_RATE_FACTOR;

        //if there were less eth blocks passed in time than expected
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
            uint excess_block_pct = (targetEthBlocksPerDiffPeriod *
                MAX_ADJUSTMENT_PERCENT) / ethBlocksSinceLastDifficultyPeriod;
            uint excess_block_pct_extra = limitLessThan(
                (excess_block_pct - 100),
                QUOTIENT_LIMIT
            );
            // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.
            //make it harder
            difficulty =
                difficulty -
                (difficulty * excess_block_pct_extra) /
                TARGET_DIVISOR;
            //by up to 50 %
        } else {
            uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod *
                MAX_ADJUSTMENT_PERCENT) / targetEthBlocksPerDiffPeriod;
            uint shortage_block_pct_extra = limitLessThan(
                shortage_block_pct - 100,
                QUOTIENT_LIMIT
            ); //always between 0 and 1000
            //make it easier
            difficulty =
                difficulty +
                ((difficulty * shortage_block_pct_extra) / TARGET_DIVISOR); //by up to 50 %
        }
        latestDifficultyPeriodStarted = block.number;
        if (difficulty < MINIMUM_TARGET_DIFFICULTY) //very difficult
        {
            difficulty = MINIMUM_TARGET_DIFFICULTY;
        }
        if (difficulty > MAXIMUM_TARGET_DIFFICULTY) //very easy
        {
            difficulty = MAXIMUM_TARGET_DIFFICULTY;
        }
        return difficulty;
    }

    // internal helper functions

    function _random() internal view returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.prevrandao, // block.difficulty
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
        return randomNum;
    }

    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if (a > b) return b;

        return a;
    }
}
