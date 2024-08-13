// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BasicDistribution} from "gif-next/contracts/distribution/BasicDistribution.sol"; 
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {ReferralId} from "gif-next/contracts/type/Referral.sol";
import {Timestamp} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed} from "gif-next/contracts/type/UFixed.sol";

contract MyDistribution is BasicDistribution {

    function initialize(
        address registry,
        NftId instanceNftId,
        IAuthorization authorization,
        address initialOwner, 
        string memory name,
        address token
    )
        public
        virtual
        initializer()
    {
        _initializeBasicDistribution(
            registry,
            instanceNftId,
            authorization,
            initialOwner,
            name,
            token);
    }
}