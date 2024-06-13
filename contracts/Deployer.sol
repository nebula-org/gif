// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {UsdcMock} from "./UsdcMock.sol";
import {BasicDistribution} from "./BasicDistribution.sol";
import {BasicPool} from "./BasicPool.sol";
import {InsuranceProduct} from "./InsuranceProduct.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";


contract Deployer  {

    UsdcMock private usdc;
    BasicDistribution private distribution;
    BasicPool private pool;
    InsuranceProduct private product;
    
    constructor(
        address registry,
        NftId instanceNftId,
        address initialOwner,
        string memory deploymentId
    ) 
    {
        usdc = new UsdcMock();

        distribution = DistributionDeployer.deployDistribution(
            registry, 
            instanceNftId, 
            initialOwner, 
            deploymentId, 
            address(usdc));

        pool = PoolDeployer.deployPool(
            registry, 
            instanceNftId, 
            initialOwner, 
            deploymentId, 
            address(usdc));

        product = ProductDeployer.deployProduct(
            registry, 
            instanceNftId, 
            initialOwner, 
            deploymentId, 
            address(usdc), 
            address(pool), 
            address(distribution));

        distribution.register();
        pool.register();
        product.register();
    }

    function getUsdc() public view returns (UsdcMock) {
        return usdc;
    }

    function getDistributionNftId() public view returns (NftId) {
        return distribution.getNftId();
    }

    function getDistribution() public view returns (BasicDistribution) {
        return distribution;
    }

    function getPoolNftId() public view returns (NftId) {
        return pool.getNftId();
    }

    function getPool() public view returns (BasicPool) {
        return pool;
    }

    function getProductNftId() public view returns (NftId) {
        return product.getNftId();
    }

    function getProduct() public view returns (InsuranceProduct) {
        return product;
    }

}

library DistributionDeployer {

    function deployDistribution(address registry,
            NftId instanceNftId,
            address initialDistributionOwner,
            string memory deploymentId,
            address token) public returns (BasicDistribution) {
        return new BasicDistribution(
            registry,
            instanceNftId,
            initialDistributionOwner,
            string.concat("BasicDistribution", deploymentId),
            token,
            "",
            ""
        );
    }

}

library PoolDeployer {

    function deployPool(address registry,
            NftId instanceNftId,
            address initialPoolOwner,
            string memory deploymentId,
            address token) public returns (BasicPool) {
        return new BasicPool(
            registry,
            instanceNftId,
            initialPoolOwner,
            string.concat("BasicPool", deploymentId),
            token,
            false,
            "",
            ""
        );
    }

}

library ProductDeployer {

    function deployProduct(address registry,
            NftId instanceNftId,
            address initialProductOwner,
            string memory deploymentId,
            address token,
            address poolAddress,
            address distributionAddress) public returns (InsuranceProduct) {
        return new InsuranceProduct(
            registry,
            instanceNftId,
            initialProductOwner,
            string.concat("InsuranceProduct", deploymentId),
            token,
            false,
            poolAddress,
            distributionAddress,
            "",
            ""
        );
    }

}