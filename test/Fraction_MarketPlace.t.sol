// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {NFT} from "../src/NFT.sol";
import {FractionToken} from "../src/FractionTokens.sol";

contract TestFractionMarketPlace {
    function setUp() public {
        address account1 = address("0x11");
        address account2 = address("0x22");

        marketPlace = new MarketPlace();
        // Deploy NFT contract
        nft = new NFT("baseUri");
        fractionT = new FractionToken(
            address(nft),
            1,
            account1,
            "FNFT_TOkens",
            "FNFT"
        );

        newDeposit = MarketPlace.DepositInfo({
            owner: account1,
            nftContractAddress: address(nft),
            nftId: 1,
            depositTimestamp: 0,
            fractionContractAddress: address(fractionT),
            supply: 0,
            totalGain: 0,
            nftFractionPrice: 0.01 ether,
            hasFractionalized: true
        });
        nft.mintTo(accountA);
    }
}
