// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Distribution} from "gif-next/contracts/distribution/Distribution.sol"; 
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {ReferralId} from "gif-next/contracts/type/Referral.sol";
import {Timestamp} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed} from "gif-next/contracts/type/UFixed.sol";

contract BasicDistribution is Distribution {
    
    constructor(
        address registry,
        NftId instanceNftId,
        address initialOwner,
        string memory name,
        address token,
        bytes memory registryData, 
        bytes memory componentData
    ) 
    {
        initialize(
            registry,
            instanceNftId,
            initialOwner,
            name,
            token,
            registryData,
            componentData);
    }

    function initialize(
        address registry,
        NftId instanceNftId,
        address initialOwner,
        string memory name,
        address token,
        bytes memory registryData, 
        bytes memory componentData
    )
        public
        virtual
        initializer()
    {
        initializeDistribution(
            registry,
            instanceNftId,
            initialOwner,
            name,
            token,
            registryData,
            componentData);
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