pragma solidity ^0.8.23;

import "src/interfaces/term/ITermRepoServicer.sol";
import "src/test/kontrol/KontrolTest.sol";

contract TermRepoServicer is ITermRepoServicer, KontrolTest {
    address _termRepoToken;
    bool _redeemAlwaysSucceeds;

    function initializeSymbolic(address termRepoToken) public {
        kevm.symbolicStorage(address(this));
        // Clear slot which holds two contract fields
        uint256 repoTokenAndRedeemSlot;
        assembly {
            repoTokenAndRedeemSlot := _termRepoToken.slot
        }
        _storeUInt256(address(this), repoTokenAndRedeemSlot, 0);
        _termRepoToken = termRepoToken;
        _redeemAlwaysSucceeds = false;
    }

    function guaranteeRedeemAlwaysSucceeds() external {
        _redeemAlwaysSucceeds = true;
    }

    function redeemTermRepoTokens(
        address redeemer,
        uint256 amountToRedeem
    ) external {
        // Function might revert in some cases
        if (!_redeemAlwaysSucceeds) {
            require(kevm.freshBool() != 0);
        }

        kevm.symbolicStorage(_termRepoToken);
        kevm.symbolicStorage(address(this));
    }

    function termRepoToken() external view returns (address) {
        return _termRepoToken;
    }

    function termRepoLocker() external view returns (address) {
        return kevm.freshAddress();
    }

    function purchaseToken() external view returns (address) {
        return kevm.freshAddress();
    }
}
