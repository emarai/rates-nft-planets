// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./AbstractERC918.sol";

contract Planets is AbstractERC918, ERC721Upgradeable {
    using Strings for uint256;
    uint256 public currentTokenId;
    string public baseUri;

    // equivalent $RTS
    // ER = Equivalent Rates
    uint public totalERSupply;

    // mining proof-of-work, adjustment, difficulty
    mapping(uint256 => bytes32) public digestForTokenId;
    uint public epochCount; // == planetminted
    uint public constant ITEM_PER_READJUSTMENT = 10;
    uint public constant MINING_RATE_FACTOR = 180; //mint the token 60 times less often than ether
    uint public latestDifficultyPeriodStarted;
    uint public constant MINIMUM_TARGET_DIFFICULTY = 2 ** 16;
    uint public constant MAXIMUM_TARGET_DIFFICULTY = 2 ** 236; // TODO: should change to 234?
    uint public constant TARGET_DIVISOR = 2000;
    uint public constant QUOTIENT_LIMIT = TARGET_DIVISOR / 2;
    uint public constant MAX_ADJUSTMENT_PERCENT = 100;

    // mining reward
    uint8 public constant decimals = 18;
    uint public constant startingAverageReward = 1000 * 10 ** uint(decimals);
    uint public rewardEra;
    uint public constant maxSupplyForEra = 1000000000 * 10 ** uint(decimals);
    uint public totalRtsPerEra;
    uint public constant BASE_REWARD = 250;

    // mining rig
    uint public miningRigUpgradePrice;
    uint8 public maximumRigLevel;
    uint8[] public miningRigPercentage;
    mapping(address => uint8) public miningRigForAddress;
    mapping(uint256 => uint256) public rtsBonusForTokenId;

    // upgradable
    address public owner;

    // future variables

    event DifficultyChange(uint difficulty);

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) public initializer {
        require(owner == address(0));

        owner = msg.sender;

        setBaseUri(_baseUri);
        challengeNumber = blockhash(block.number - 1);
        latestDifficultyPeriodStarted = block.number;
        difficulty = MAXIMUM_TARGET_DIFFICULTY;
        miningRigUpgradePrice = 0.03 ether;
        maximumRigLevel = 10;
        miningRigPercentage = [0, 5, 10, 15, 22, 29, 36, 46, 56, 66, 80];
        __ERC721_init(_name, _symbol);
    }

    // NFT Functions
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json"))
                : "";
    }

    // ERC-918 Functions

    function mint(
        uint256 nonce,
        bytes32 challengeDigest
    ) public virtual override returns (bool success) {
        currentTokenId = ++currentTokenId;
        // CHALLENGE CHECK
        // check digest
        bytes32 digest = _hash(nonce, challengeDigest);

        //  digest must be smaller than difficulty
        if (uint256(digest) > difficulty) revert("Nonce incorrect");

        // only allow for one solution, each tokenId
        bytes32 solution = digestForTokenId[currentTokenId];
        if (solution != 0x0) revert("Solution exist");

        digestForTokenId[currentTokenId] = digest;

        // mint nft
        _safeMint(msg.sender, currentTokenId);

        uint rtsForPlanet = 100 + (uint256(digest) & 0x3e8); // RTS MASK

        // bonus rts from mining rig
        uint rtsBonus = (miningRigPercentage[miningRigForAddress[msg.sender]] *
            rtsForPlanet) / 100;

        if (rtsBonus > 0) {
            rtsBonusForTokenId[currentTokenId] = rtsBonus;
        }
        tokensMinted += rtsForPlanet + rtsBonus;

        // TODO: diagnostics
        return true;
    }

    function setMiningRigUpgradePrice(uint256 priceInEth) public onlyOwner {
        miningRigUpgradePrice = priceInEth;
    }

    function upgradeMiningRig(uint8 amount) public payable {
        require(msg.value >= miningRigUpgradePrice * amount);

        uint8 level = miningRigForAddress[msg.sender] + amount;

        require(level <= maximumRigLevel);

        miningRigForAddress[msg.sender] = level;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function _hash(
        uint256 nonce,
        bytes32 challengeDigest
    ) internal view virtual override returns (bytes32 digestResult) {
        digestResult = keccak256(
            abi.encodePacked(challengeNumber, msg.sender, nonce)
        );
        if (digestResult != challengeDigest) revert("Digest is different");

        return digestResult;
    }

    function checkHash(
        uint256 nonce,
        bytes32 challengeDigest
    ) public view returns (bytes32 digest) {
        return _hash(nonce, challengeDigest);
    }

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns (uint) {
        return difficulty;
    }

    function getMiningReward() public pure returns (uint) {
        return startingAverageReward;
    }

    function getMiningTarget() public view returns (uint) {
        return difficulty;
    }

    function getPlanetMinted() public view returns (uint) {
        return currentTokenId;
    }

    function getTotalStatsPerTokenId(
        uint256 id
    ) public view returns (uint, uint, uint, uint, uint, uint) {
        uint256 digest = uint256(digestForTokenId[id]);
        uint x = (digest >> (12 * 4)) & 0x3e8; // X MASK
        uint y = (digest >> (12 * 5)) & 0x3e8; // Y MASK

        uint planetZoneMultiplier = getPlanetZone(x, y) * 10;

        uint rts = 100 + (digest & 0x3e8) + rtsBonusForTokenId[id]; // RTS MASK

        uint prts = BASE_REWARD + ((digest >> 12) & 0x3e8); // PRTS MASK
        uint arts = BASE_REWARD + ((digest >> (12 * 2)) & 0x3e8); // ARTS MASK
        uint mrts = BASE_REWARD + ((digest >> (12 * 3)) & 0x3e8); // ARTS MASK

        if (planetZoneMultiplier > 0) {
            rts += (rts * planetZoneMultiplier) / 100;
            prts += (prts * planetZoneMultiplier) / 100;
            arts += (arts * planetZoneMultiplier) / 100;
            mrts += (mrts * planetZoneMultiplier) / 100;
        }

        return (rts, prts, arts, mrts, x, y);
    }

    function getPlanetZone(uint x, uint y) public pure returns (uint zone) {
        if (x > 500) {
            x -= 500;
        } else {
            x = 500 - x;
        }

        if (y > 500) {
            y -= 500;
        } else {
            y = 500 - y;
        }

        uint distFromMiddle = FixedPointMathLib.sqrt(x ** 2 + y ** 2);

        zone = distFromMiddle / 80;

        return zone;
    }

    // internal functions from abstract
    function _reward() internal virtual override returns (uint) {
        return 500; // startingAverageReward / (2 ** rewardEra);
    }

    function _newEpoch(
        uint256 rtsMinted
    ) internal virtual override returns (uint) {
        // decrease planet $RTS every 1 million $RTS minted (planet-wise)
        if ((tokensMinted + rtsMinted) > maxSupplyForEra) {
            rewardEra = rewardEra + 1;
        }
        epochCount = ++epochCount;

        // adjust difficulty every 10 items minted
        if (epochCount % ITEM_PER_READJUSTMENT == 0) {
            _adjustDifficulty();
        }

        challengeNumber = blockhash(block.number - 1);

        return epochCount;
    }

    function _adjustDifficulty() internal virtual override returns (uint) {
        if (epochCount % ITEM_PER_READJUSTMENT != 0) {
            return difficulty;
        }

        uint ethBlocksSinceLastDifficultyPeriod = block.number -
            latestDifficultyPeriodStarted;
        //assume 1800 goerli base blocks per hour
        //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
        uint epochsMined = ITEM_PER_READJUSTMENT;
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

        emit DifficultyChange(difficulty);
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

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner is allowed to perform this action"
        );
        _;
    }
}
