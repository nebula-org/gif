// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Amount, AmountLib} from "gif-next/contracts/type/Amount.sol";
import {Product} from "gif-next/contracts/product/Product.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {ReferralId} from "gif-next/contracts/type/Referral.sol";
import {Timestamp, Seconds} from "gif-next/contracts/type/Timestamp.sol";

uint64 constant SPECIAL_ROLE_INT = 11111;

contract InsuranceProduct is Product {

    constructor(
        address registry,
        NftId instanceNftid,
        address initialOwner,
        string memory name,
        address token,
        bool isInterceptor,
        address pool,
        address distribution,
        bytes memory registryData, 
        bytes memory componentData 
    )
    {
        initialize(
            registry,
            instanceNftid,
            initialOwner,
            name,
            token,
            isInterceptor,
            pool,
            distribution,
            registryData,
            componentData); 
    }


    function initialize(
        address registry,
        NftId instanceNftid,
        address initialOwner,
        string memory name,
        address token,
        bool isInterceptor,
        address pool,
        address distribution,
        bytes memory registryData, 
        bytes memory componentData 
    )
        public
        virtual
        initializer()
    {
        initializeProduct(
            registry,
            instanceNftid,
            initialOwner,
            name,
            token,
            isInterceptor,
            pool,
            distribution,
            registryData,
            componentData); 
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

    // TODO: required?
    // function updateRiskState(
    //     RiskId id,
    //     StateId state
    // ) public {
    //     _updateRiskState(
    //         id,
    //         state
    //     );
    // }
    
    function createApplication(
        address applicationOwner,
        RiskId riskId,
        Amount sumInsuredAmount,
        Seconds lifetime,
        bytes memory applicationData,
        NftId bundleNftId,
        ReferralId referralId
    ) public returns (NftId nftId) {
        return _createApplication(
            applicationOwner,
            riskId,
            sumInsuredAmount,
            lifetime,
            bundleNftId,
            referralId,
            applicationData
        );
    }

    function underwrite(
        NftId policyNftId,
        bool requirePremiumPayment,
        Timestamp activateAt
    ) public {
        _collateralize(policyNftId, requirePremiumPayment, activateAt);
    }

    // function collectPremium(
    //     NftId policyNftId,
    //     Timestamp activateAt
    // ) public {
    //     _collectPremium(policyNftId, activateAt);
    // }

    // function activate(
    //     NftId policyNftId,
    //     Timestamp activateAt
    // ) public {
    //     _activate(policyNftId, activateAt);
    // }

    function close(
        NftId policyNftId
    ) public {
        _close(policyNftId);
    }

    // function doSomethingSpecial() 
    //     public 
    //     restricted()
    //     returns (bool) 
    // {
    //     return true;
    // }

    // function doWhenNotLocked() 
    //     public 
    //     restricted()
    //     returns (bool) 
    // {
    //     return true;
    // }

}