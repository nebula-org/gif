// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {MyDistribution} from "./MyDistribution.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {BasicDistributionAuthorization} from "gif-next/contracts/distribution/BasicDistributionAuthorization.sol";

library DistributionDeployer {

    function deployDistribution(address registry,
            NftId instanceNftId,
            address initialDistributionOwner,
            string memory deploymentId,
            address token) public returns (MyDistribution) {
        return new MyDistribution(
            registry,
            instanceNftId,
            new BasicDistributionAuthorization(string.concat("MyDistribution", deploymentId)),
            initialDistributionOwner,
            string.concat("MyDistribution", deploymentId),
            token
        );
    }
}
