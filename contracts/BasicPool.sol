// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/types/Amount.sol";
import {Fee} from "gif-next/types/Fee.sol";
import {NftId} from "gif-next/types/NftId.sol";
import {Pool} from "gif-next/components/Pool.sol";
import {Seconds} from "gif-next/types/Timestamp.sol";
import {UFixed} from "gif-next/types/UFixed.sol";

contract BasicPool is Pool {
    
    constructor(
        address registry,
        NftId instanceNftId,
        address token,
        bool isInterceptor,
        bool isConfirmingApplication,
        UFixed collateralizationLevel,
        UFixed retentionLevel,
        address initialOwner
    ) 
    {
        initialize(
            registry,
            instanceNftId,
            token,
            isInterceptor,
            isConfirmingApplication,
            collateralizationLevel,
            retentionLevel,
            initialOwner
        );
    }

    function initialize(
        address registry,
        NftId instanceNftId,
        address token,
        bool isInterceptor,
        bool isConfirmingApplication,
        UFixed collateralizationLevel,
        UFixed retentionLevel,
        address initialOwner
    )
        public
        virtual
        initializer()
    {
        initializePool(
            registry,
            instanceNftId,
            "BasicPool",
            token,
            isInterceptor,
            // TODO refactor
            // false, // externally managed
            // isConfirmingApplication, // verifying applications
            // collateralizationLevel,
            // retentionLevel,
            initialOwner,
            "");
    }

    function createBundle(
        Fee memory fee,
        uint256 initialAmount,
        Seconds lifetime,
        bytes calldata filter
    )
        external
        virtual 
        returns(NftId bundleNftId)
    {
        address owner = msg.sender;
        bundleNftId = _createBundle(
            owner,
            fee,
            AmountLib.toAmount(initialAmount),
            lifetime,
            filter
        );
    }

}