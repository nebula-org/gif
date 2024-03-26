// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Distribution} from "gif-next/contracts/components/Distribution.sol"; 
import {Fee} from "gif-next/contracts/types/Fee.sol";
import {NftId} from "gif-next/contracts/types/NftId.sol";
import {ReferralId} from "gif-next/contracts/types/Referral.sol";
import {Timestamp} from "gif-next/contracts/types/Timestamp.sol";
import {UFixed} from "gif-next/contracts/types/UFixed.sol";

contract BasicDistribution is Distribution {
    
    constructor(
        string memory name,
        address registry,
        NftId instanceNftId,
        address token,
        Fee memory minDistributionOwnerFee,
        Fee memory distributionFee,
        address initialOwner
    ) 
    {
        initialize(
            registry,
            instanceNftId,
            name,
            token,
            minDistributionOwnerFee,
            distributionFee,
            initialOwner);
    }

    function initialize(
        address registry,
        NftId instanceNftId,
        string memory name,
        address token,
        Fee memory minDistributionOwnerFee,
        Fee memory distributionFee,
        address initialOwner
    )
        public
        virtual
        initializer()
    {
        initializeDistribution(
            registry,
            instanceNftId,
            name,
            token,
            minDistributionOwnerFee,
            distributionFee,
            initialOwner,
            ""
        );
    }

    /**
     * @dev lets distributors create referral codes.
     * referral codes need to be unique
     */
    function createReferral(
        NftId distributorNftId,
        string memory code,
        UFixed discountPercentage,
        uint32 maxReferrals,
        Timestamp expiryAt,
        bytes memory data
    )
        external
        returns (ReferralId referralId)
    {
        return _createReferral(
            distributorNftId,
            code,
            discountPercentage,
            maxReferrals,
            expiryAt,
            data);
    }
}