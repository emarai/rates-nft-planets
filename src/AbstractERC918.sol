// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./EIP918Interface.sol";

/**
 * ERC Draft Token Standard #918 Interface
 * Proof of Work Mineable Token
 *
 * This Abstract contract describes a minimal set of behaviors (hash, reward, epoch, and difficulty adjustment)
 * and state required to build a Proof of Work driven mineable token.
 *
 * https://github.com/ethereum/EIPs/pull/918
 */
abstract contract AbstractERC918 is EIP918Interface {
    // generate a new challenge number after a new reward is minted
    bytes32 public challengeNumber;

    // the current mining difficulty
    uint public difficulty;

    // cumulative counter of the total minted tokens
    uint public tokensMinted;

    // track read only minting statistics
    struct Statistics {
        address lastRewardTo;
        uint lastRewardAmount;
        uint lastRewardEthBlockNumber;
        uint lastRewardTimestamp;
    }

    Statistics public statistics;

    /*
     * Externally facing mint function that is called by miners to validate challenge digests, calculate reward,
     * populate statistics, mutate epoch variables and adjust the solution difficulty as required. Once complete,
     * a Mint event is emitted before returning a success indicator.
     **/
    function mint(
        uint256 nonce,
        bytes32 challengeDigest
    ) public virtual returns (bool success) {
        // perform the hash function validation
        _hash(nonce, challengeDigest);

        // calculate the current reward
        uint rewardAmount = _reward();

        // increment the minted tokens amount
        tokensMinted += rewardAmount;

        uint epochCount = _newEpoch(nonce);

        _adjustDifficulty();

        //populate read only diagnostics data
        statistics = Statistics(
            msg.sender,
            rewardAmount,
            block.number,
            block.timestamp
        );

        // send Mint event indicating a successful implementation
        emit Mint(msg.sender, rewardAmount, epochCount, challengeNumber);

        return true;
    }

    /*
     * Internal interface function _hash. Overide in implementation to define hashing algorithm and
     * validation
     **/
    function _hash(
        uint256 nonce,
        bytes32 challengeDigest
    ) internal virtual returns (bytes32 digest);

    /*
     * Internal interface function _reward. Overide in implementation to calculate and return reward
     * amount
     **/
    function _reward() internal virtual returns (uint);

    /*
     * Internal interface function _newEpoch. Overide in implementation to define a cutpoint for mutating
     * mining variables in preparation for the next epoch
     **/
    function _newEpoch(uint256 nonce) internal virtual returns (uint);

    /*
     * Internal interface function _adjustDifficulty. Overide in implementation to adjust the difficulty
     * of the mining as required
     **/
    function _adjustDifficulty() internal virtual returns (uint);
}
