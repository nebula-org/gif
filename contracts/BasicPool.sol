// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {Pool} from "gif-next/contracts/pool/Pool.sol";
import {Seconds} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed} from "gif-next/contracts/type/UFixed.sol";

contract BasicPool is Pool {
    
    constructor(
        address registry,
        NftId instanceNftId,
        address initialOwner,
        string memory name,
        address token,
        bool isInterceptor,
        bytes memory registryData, 
        bytes memory componentData
    ) 
    {
        initialize(
            registry,
            instanceNftId,
            name,
            token,
            isInterceptor,
            initialOwner,
            registryData,
            componentData
        );
    }

    function initialize(
        address registry,
        NftId instanceNftId,
        string memory name,
        address token,
        bool isInterceptor,
        address initialOwner,
        bytes memory registryData, 
        bytes memory componentData
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
            registryData,
            componentData);
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