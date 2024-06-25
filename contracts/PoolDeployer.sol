// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {MyPool} from "./MyPool.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {BasicPoolAuthorization} from "gif-next/contracts/pool/BasicPoolAuthorization.sol";

library PoolDeployer {

    function deployPool(address registry,
            NftId instanceNftId,
            address initialPoolOwner,
            string memory deploymentId,
            address token) public returns (MyPool) {
        return new MyPool(
            registry,
            instanceNftId,
            token,
            new BasicPoolAuthorization(string.concat("MyPool", deploymentId)),
            initialPoolOwner,
            string.concat("MyPool", deploymentId)
        );
    }
}
