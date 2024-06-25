// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {BasicPool} from "gif-next/contracts/pool/BasicPool.sol";
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {Seconds} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed} from "gif-next/contracts/type/UFixed.sol";

contract MyPool is BasicPool {
    
    constructor(
        address registry,
        NftId instanceNftId,
        address token,
        IAuthorization authorization,
        address initialOwner,
        string memory name
    ) 
    {
        initialize(
            registry,
            instanceNftId,
            name,
            token,
            authorization,
            initialOwner
        );
    }

    function initialize(
        address registry,
        NftId instanceNftId,
        string memory name,
        address token,
        IAuthorization authorization,
        address initialOwner
    )
        public
        virtual
        initializer()
    {
        _initializeBasicPool(
            registry,
            instanceNftId,
            authorization,
            token,
            name,
            initialOwner);
    }

    function createBundle(
        address owner,
        Fee memory fee,
        uint256 initialAmount,
        Seconds lifetime,
        bytes calldata filter
    )
        external
        virtual 
        returns(NftId bundleNftId)
    {
        bundleNftId = _createBundle(
            owner,
            fee,
            AmountLib.toAmount(initialAmount),
            lifetime,
            filter
        );
    }

}