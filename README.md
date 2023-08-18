# Rates NFT Planets (ERC-721 / ERC-918)

```
Humanity has discovered a revolutionary material capable of doing Room-Temperature Superconductor ($RTS), also referred to as Rates. Explore new planets, extract resources, and elevate in a new age of technological marvels.
```

## What is it?

This contract implement the mining of NFT on Rates Protocol. Every NFT will need to be mined using
ERC-918 implementation, similar to 0xBTC, KiwiToken, etc. Instead of coins, this contract will mint
ERC-721 NFTs.

## Planets

Planets contains resources, which can be mined later with our game contract (soon). All resources will be ERC-20, and the total amount is determined randomly, derived from challenge digest. The resources are as follows,

| Resource | Description                                                          |
| -------- | -------------------------------------------------------------------- |
| \$RTS    | The core protocol token, will be used for many different activities. |
| \$PRTS   | Plant token, represents your resource of plant based resources.      |
| \$ARTS   | Animal token, represents your resources of livestocks resources.     |
| \$MRTS   | Mineral token, represents your resources of mineral resources.       |

## Mining Rig

Miners can buy upgrades to increase their mined planet resources. Each level have different multiplier,

| Level | Multiplier |
| ----- | ---------- |
| 0     | +0%        |
| 1     | +5%        |
| 2     | +10%       |
| 3     | +15%       |
| 4     | +22%       |
| 5     | +29%       |
| 6     | +36%       |
| 7     | +46%       |
| 8     | +56%       |
| 9     | +66%       |
| 10    | +80%       |

## Zone Multiplier

The whole map is 1000x1000 pixel-wide. Every player will begin at the middle of the map (500, 500).
The farthest your planet, the higher the multiplier.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```
