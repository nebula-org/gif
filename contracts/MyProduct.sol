// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Amount, AmountLib} from "gif-next/contracts/type/Amount.sol";
import {BasicProduct} from "gif-next/contracts/product/BasicProduct.sol";
import {ClaimId} from "gif-next/contracts/type/ClaimId.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {PayoutId} from "gif-next/contracts/type/PayoutId.sol";
import {ReferralId} from "gif-next/contracts/type/Referral.sol";
import {RequestId} from "gif-next/contracts/type/RequestId.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {StateId} from "gif-next/contracts/type/StateId.sol";
import {Timestamp, Seconds} from "gif-next/contracts/type/Timestamp.sol";

contract MyProduct is BasicProduct {

    event LogSimpleProductRequestAsyncFulfilled(RequestId requestId, string responseText, uint256 responseDataLength);
    event LogSimpleProductRequestSyncFulfilled(RequestId requestId, string responseText, uint256 responseDataLength);

    error ErrorSimpleProductRevertedWhileProcessingResponse(RequestId requestId);

    function initialize(
        address registry,
        NftId instanceNftid,
        string memory name,
        address token,
        IAuthorization authorization,
        address initialOwner
    )
        public
        initializer()
    {
        _initializeBasicProduct(
            registry,
            instanceNftid,
            name,
            token,
            IComponents.ProductInfo({
                isProcessingFundedClaims: false,
                isInterceptingPolicyTransfers: false,
                hasDistribution: true,
                expectedNumberOfOracles: 0,
                numberOfOracles: 0,
                poolNftId: NftIdLib.zero(),
                distributionNftId: NftIdLib.zero(),
                oracleNftId: new NftId[](0),
                productFee: FeeLib.zero(),
                processingFee: FeeLib.zero(),
                distributionFee: FeeLib.zero(),
                minDistributionOwnerFee: FeeLib.zero(),
                poolFee: FeeLib.zero(),
                stakingFee: FeeLib.zero(),
                performanceFee: FeeLib.zero()
            }),
            authorization,
            initialOwner); 
    }

    function createRisk(
        RiskId id,
        bytes memory data
    ) public {
        _createRisk(
            id,
            data
        );
    }

    function updateRisk(
        RiskId id,
        bytes memory data
    ) public {
        _updateRisk(
            id,
            data
        );
    }

    function updateRiskState(
        RiskId id,
        StateId state
    ) public {
        _updateRiskState(
            id,
            state
        );
    }

    function createApplication(
        address applicationOwner,
        RiskId riskId,
        uint256 sumInsured,
        Seconds lifetime,
        bytes memory applicationData,
        NftId bundleNftId,
        ReferralId referralId
    ) public returns (NftId nftId) {
        Amount sumInsuredAmount = AmountLib.toAmount(sumInsured);
        Amount premiumAmount = calculatePremium(
            sumInsuredAmount,
            riskId,
            lifetime,
            applicationData,
            bundleNftId,
            referralId);

        return _createApplication(
            applicationOwner,
            riskId,
            sumInsuredAmount,
            premiumAmount,
            lifetime,
            bundleNftId,
            referralId,
            applicationData
        );
    }

    function createPolicy(
        NftId applicationNftId,
        bool requirePremiumPayment,
        Timestamp activateAt
    ) public {
        _createPolicy(applicationNftId, activateAt);
        if (requirePremiumPayment == true) {
            _collectPremium(applicationNftId, activateAt);
        }
    }

    function collectPremium(
        NftId policyNftId,
        Timestamp activateAt
    ) public {
        _collectPremium(policyNftId, activateAt);
    }

    function activate(
        NftId policyNftId,
        Timestamp activateAt
    ) public {
        _activate(policyNftId, activateAt);
    }

    function close(
        NftId policyNftId
    ) public {
        _close(policyNftId);
    }

    function submitClaim(
        NftId policyNftId,
        Amount claimAmount,
        bytes memory submissionData
    ) public returns (ClaimId) {
        return _submitClaim(policyNftId, claimAmount, submissionData);
    }

    function confirmClaim(
        NftId policyNftId,
        ClaimId claimId,
        Amount confirmedAmount,
        bytes memory processData
    ) public {
        _confirmClaim(policyNftId, claimId, confirmedAmount, processData);
    }

    function declineClaim(
        NftId policyNftId,
        ClaimId claimId,
        bytes memory processData
    ) public {
        _declineClaim(policyNftId, claimId, processData);
    }

    function closeClaim(
        NftId policyNftId,
        ClaimId claimId
    ) public {
        _closeClaim(policyNftId, claimId);
    }

    function createPayout(
        NftId policyNftId,
        ClaimId claimId,
        Amount amount,
        bytes memory data
    ) public returns (PayoutId) {
        return _createPayout(policyNftId, claimId, amount, data);
    }

    function processPayout(
        NftId policyNftId,
        PayoutId payoutId
    ) public {
        _processPayout(policyNftId, payoutId);
    }

}