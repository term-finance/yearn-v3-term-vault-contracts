// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {ITermController, AuctionMetadata} from "../../interfaces/term/ITermController.sol";

struct TermAuctionResults {
    AuctionMetadata[] auctionMetadata;
    uint8 numOfAuctions;
}

contract MockTermController is ITermController {
    mapping(bytes32 => TermAuctionResults) internal auctionResults;
    mapping(address => bool) internal notTermDeployedContracts;

    function isTermDeployed(address contractAddress) external view returns (bool) {
        return !notTermDeployedContracts[contractAddress];
    }

    function markNotTermDeployed(address contractAddress) external {
        notTermDeployedContracts[contractAddress] = true;
    }

    function getProtocolReserveAddress() external view returns (address) {
        return address(100);
    }

    function setOracleRate(bytes32 termRepoId, uint256 oracleRate) external {
        AuctionMetadata memory metadata;

        metadata.auctionClearingRate = oracleRate;

        delete auctionResults[termRepoId];
        auctionResults[termRepoId].auctionMetadata.push(metadata);
        auctionResults[termRepoId].numOfAuctions = 1;
    }

    function getTermAuctionResults(bytes32 termRepoId) external view returns (AuctionMetadata[] memory auctionMetadata, uint8 numOfAuctions) {
        return (auctionResults[termRepoId].auctionMetadata, auctionResults[termRepoId].numOfAuctions);
    }
}