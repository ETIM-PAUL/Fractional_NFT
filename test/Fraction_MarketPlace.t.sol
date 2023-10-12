// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {NFT} from "../src/NFT.sol";
import {FractionToken} from "../src/FractionTokens.sol";
import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract TestFractionMarketPlace is Test {
    NFT private nft;
    MarketPlace private marketPlace;
    FractionToken private fractionT;

    MarketPlace.DepositInfo newDeposit;

    address account1 = address(0x11);
    address account2 = address(0x22);

    function setUp() public {
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
        nft.mintTo(account1);
    }

    function testDepositNft() external {
        vm.startPrank(account1);
        nft.approve(address(marketPlace), 1);
        bool deposited = marketPlace.depositNft(
            newDeposit.nftContractAddress,
            1
        );

        assertTrue(deposited);
    }
}
