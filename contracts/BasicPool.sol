// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/types/Amount.sol";
import {Fee} from "gif-next/contracts/types/Fee.sol";
import {NftId} from "gif-next/contracts/types/NftId.sol";
import {Pool} from "gif-next/contracts/components/Pool.sol";
import {Seconds} from "gif-next/contracts/types/Timestamp.sol";
import {UFixed} from "gif-next/contracts/types/UFixed.sol";

contract BasicPool is Pool {
    
    constructor(
        string memory name,
        address registry,
        NftId instanceNftId,
        address token,
        bool isInterceptor,
        address initialOwner
    ) 
    {
        initialize(
            name,
            registry,
            instanceNftId,
            token,
            isInterceptor,
            initialOwner
        );
    }

    function initialize(
        string memory name,
        address registry,
        NftId instanceNftId,
        address token,
        bool isInterceptor,
        address initialOwner
    )
        public
        virtual
        initializer()
    {
        initializePool(
            registry,
            instanceNftId,
            name,
            token,
            isInterceptor,
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