// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {ITermAuctionOfferLocker} from "../../interfaces/term/ITermAuctionOfferLocker.sol";
import {ITermAuction} from "../../interfaces/term/ITermAuction.sol";
import {MockTermRepoLocker} from "./MockTermRepoLocker.sol";
import {MockTermRepoToken} from "./MockTermRepoToken.sol";

contract MockTermAuctionOfferLocker is ITermAuctionOfferLocker {
    error OfferUnlockingFailed();

    address public purchaseToken;
    address public termRepoServicer;
    uint256 public auctionStartTime;
    MockTermRepoLocker internal repoLocker;
    ITermAuction internal auction;
    mapping(bytes32 => TermAuctionOffer) internal lockedOffers;

    constructor(
        ITermAuction _auction,
        address _repoLocker,
        address _repoServicer,
        address _purchaseToken
    ) {
        auction = _auction;
        purchaseToken = _purchaseToken;
        termRepoServicer = _repoServicer;
        repoLocker = MockTermRepoLocker(_repoLocker);
        auctionStartTime = 0;
    }

    function termRepoId() external view returns (bytes32) {
        return auction.termRepoId();
    }

    function termAuctionId() external view returns (bytes32) {
        return auction.termRepoId();
    }

    function auctionEndTime() external view returns (uint256) {
        return auction.auctionEndTime();
    }

    function revealTime() external view returns (uint256) {
        return auction.auctionEndTime();
    }

    function lockedOffer(bytes32 id) external view returns (TermAuctionOffer memory) {
        return lockedOffers[id];
    }

    function lockOffers(
        TermAuctionOfferSubmission[] calldata offerSubmissions
    ) external returns (bytes32[] memory offerIds) {
        offerIds = new bytes32[](offerSubmissions.length);

        for (uint256 i; i < offerSubmissions.length; i++) {
            TermAuctionOfferSubmission memory submission = offerSubmissions[i];
            TermAuctionOffer memory offer = lockedOffers[submission.id];

            // existing offer
            if (offer.amount > 0) {
                if (offer.amount > submission.amount) {
                    // current amount > new amount, release tokens
                    repoLocker.releasePurchaseTokens(msg.sender, offer.amount - submission.amount);
                } else if (offer.amount < submission.amount) {
                    repoLocker.lockPurchaseTokens(msg.sender, submission.amount - offer.amount);
                }
                // update locked amount
                offer.amount = submission.amount;
            } else {
                bytes32 offerId = keccak256(abi.encodePacked(submission.id,msg.sender,address(this)));

                offer.id = offerId;
                offer.offeror = submission.offeror;
                offer.offerPriceHash = submission.offerPriceHash;
                offer.amount = submission.amount;
                offer.purchaseToken = submission.purchaseToken;

                repoLocker.lockPurchaseTokens(msg.sender, offer.amount);
            }
            lockedOffers[offer.id] = offer;
            offerIds[i] = offer.id;
        }
    }

    function processOffer(MockTermRepoToken mockRepoToken, bytes32 offerId, uint256 fillAmount, uint256 repoTokenAmount) external {
        require(lockedOffers[offerId].amount >= fillAmount);
        uint256 remainingAmount = lockedOffers[offerId].amount - fillAmount;

        lockedOffers[offerId].amount = remainingAmount;

        mockRepoToken.mint(lockedOffers[offerId].offeror, repoTokenAmount);
        repoLocker.releasePurchaseTokens(lockedOffers[offerId].offeror, remainingAmount);
    }

    function unlockOffers(bytes32[] calldata offerIds) external {
        for (uint256 i; i < offerIds.length; i++) {
            bytes32 offerId = offerIds[i];
            repoLocker.releasePurchaseTokens(msg.sender, lockedOffers[offerId].amount);
            delete lockedOffers[offerId];
        }
    }

    function unlockOfferPartial(bytes32 offerId, address offeror, uint256 amount) external {
        delete lockedOffers[offerId];
        repoLocker.releasePurchaseTokens(offeror, amount);
    }
}
