// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {MyPool} from "./MyPool.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";

library PoolDeployer {

    function deployPool(address registry,
            NftId instanceNftId,
            address owner,
            string memory name,
            IAuthorization auth,
            address token) public returns (MyPool) {
        return new MyPool(
            registry,
            instanceNftId,
            token,
            auth,
            owner,
            name
        );
    }
}
