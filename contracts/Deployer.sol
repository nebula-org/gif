// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {BasicDistribution} from "./BasicDistribution.sol";
import {BasicPool} from "./BasicPool.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {IInstance} from "gif-next/contracts/instance/Instance.sol";
import {InstanceReader} from "gif-next/contracts/instance/InstanceReader.sol";
import {InsuranceProduct} from "./InsuranceProduct.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {SecondsLib} from "gif-next/contracts/type/Seconds.sol";
import {ReferralLib} from "gif-next/contracts/type/Referral.sol";
import {RiskId, RiskIdLib} from "gif-next/contracts/type/RiskId.sol";
import {UFixedLib} from "gif-next/contracts/type/UFixed.sol";
import {UsdcMock} from "./UsdcMock.sol";
import {IRegistry} from "gif-next/contracts/registry/IRegistry.sol";
import {IInstanceService} from "gif-next/contracts/instance/IInstanceService.sol";
import {INSTANCE} from "gif-next/contracts/type/ObjectType.sol";
import {VersionPart} from "gif-next/contracts/type/Version.sol";
import {AccessManagerExtendedInitializeable} from "gif-next/contracts/shared/AccessManagerExtendedInitializeable.sol";
import {PRODUCT_OWNER_ROLE, DISTRIBUTION_OWNER_ROLE, POOL_OWNER_ROLE} from "gif-next/contracts/type/RoleId.sol";
import {StateId} from "gif-next/contracts/type/StateId.sol";
import {ChainNft} from "gif-next/contracts/registry/ChainNft.sol";

contract Deployer  {

    IRegistry private registry;
    IInstance private instance;
    NftId private instanceNftId;
    InstanceReader private instanceReader;
    UsdcMock private usdc;
    BasicDistribution private distribution;
    BasicPool private pool;
    InsuranceProduct private product;
    NftId private bundleNftId;
    RiskId private riskId;
    
    constructor(
        address registryAddress,
        string memory deploymentId
    ) 
    {
        // fetch required components
        address theAllmighty = msg.sender;
        registry = IRegistry(registryAddress);
        IInstanceService instanceService = IInstanceService(registry.getServiceAddress(INSTANCE(), VersionPart.wrap(3)));
        (instance, instanceNftId) = instanceService.createInstanceClone();
        ChainNft chainNft = ChainNft(registry.getChainNftAddress());
        instanceReader = instance.getInstanceReader();

        // grant correct roles
        AccessManagerExtendedInitializeable instanceAccessManager = instance.getInstanceAccessManager();
        instanceAccessManager.grantRole(PRODUCT_OWNER_ROLE().toInt(), address(this), 0);
        instanceAccessManager.grantRole(PRODUCT_OWNER_ROLE().toInt(), theAllmighty, 0);
        instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE().toInt(), address(this), 0);
        instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE().toInt(), theAllmighty, 0);
        instanceAccessManager.grantRole(POOL_OWNER_ROLE().toInt(), address(this), 0);
        instanceAccessManager.grantRole(POOL_OWNER_ROLE().toInt(), theAllmighty, 0);        
        Fee memory bundleFee = FeeLib.toFee(UFixedLib.zero(), 0);

        // deploy token and components
        usdc = new UsdcMock();

        distribution = DistributionDeployer.deployDistribution(
            registryAddress, 
            instanceNftId, 
            address(this), 
            deploymentId, 
            address(usdc));
        distribution.register();

        pool = PoolDeployer.deployPool(
            registryAddress, 
            instanceNftId, 
            address(this), 
            deploymentId, 
            address(usdc));
        pool.register();
        pool.approveTokenHandler(AmountLib.max());

        product = ProductDeployer.deployProduct(
            registryAddress, 
            instanceNftId, 
            address(this), 
            deploymentId, 
            address(usdc), 
            address(pool), 
            address(distribution));
        product.register();


        // create a bundle with a coverage of 10k for 30 days
        usdc.approve(getPoolTokenHandler(), 10000 * 1000000);
        bundleNftId = pool.createBundle(
            address(this),
            bundleFee, 
            10000 * 1000000, 
            SecondsLib.toSeconds(30 * 24 * 60 * 60), 
            ""
        );

        // create risk
        riskId = RiskIdLib.toRiskId("1234");
        bytes memory data = "riskdata";
        product.createRisk(riskId, data);

        // move ownership of instance, component and bundle nfts to instance owner
        chainNft.safeTransferFrom(address(this), theAllmighty, instanceNftId.toInt());
        chainNft.safeTransferFrom(address(this), theAllmighty, distribution.getNftId().toInt());
        chainNft.safeTransferFrom(address(this), theAllmighty, pool.getNftId().toInt());
        chainNft.safeTransferFrom(address(this), theAllmighty, product.getNftId().toInt());
        chainNft.safeTransferFrom(address(this), theAllmighty, bundleNftId.toInt());

        // transfer 10m usdc to owner
        usdc.approve(address(this), 10000000000000);
        usdc.transferFrom(address(this), theAllmighty, 10000000000000);
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

    function getPoolTokenHandler() public view returns (address) {
        IComponents.ComponentInfo memory poolComponentInfo = instanceReader.getComponentInfo(getPoolNftId());
        return address(poolComponentInfo.tokenHandler);
    }

    function getProductNftId() public view returns (NftId) {
        return product.getNftId();
    }

    function getProduct() public view returns (InsuranceProduct) {
        return product;
    }

    function getProductTokenHandler() public view returns (address) {
        IComponents.ComponentInfo memory productComponentInfo = instanceReader.getComponentInfo(getProductNftId());
        return address(productComponentInfo.tokenHandler);
    }

    function getInitialBundleNftId() public view returns (NftId) {
        return bundleNftId;
    }

    function getInitialRiskId() public view returns (RiskId) {
        return riskId;
    }

    function createRisk(string memory riskIdStr, bytes memory data) public returns (RiskId riskId) {
        RiskId riskId = RiskIdLib.toRiskId(riskIdStr);
        product.createRisk(riskId, data);
    }

    function sendUsdcTokens(address recipient) public {
        usdc.transfer(recipient, 1000000);
    }

    function createBundle(address owner, uint256 amount, uint256 lifetimeInDays) public returns (NftId newBundleNftId) {
        Fee memory bundleFee = FeeLib.toFee(UFixedLib.zero(), 0);
        newBundleNftId = pool.createBundle(
            owner,
            bundleFee, 
            amount, 
            SecondsLib.toSeconds(lifetimeInDays * 24 * 60 * 60), 
            ""
        );
    }

    function applyForPolicy(address customer, RiskId riskId, uint256 amount, uint256 lifetimeInDays, NftId bundleNftId) public returns (NftId policyNftId) {
        policyNftId = product.createApplication(
            customer,
            riskId,
            AmountLib.toAmount(amount),
            SecondsLib.toSeconds(lifetimeInDays * 24 * 60 * 60),
            "",
            bundleNftId,
            ReferralLib.zero()
        );
    }

    function getPolicyState(NftId policyNftId) public view returns (StateId) {
        return instanceReader.getPolicyState(policyNftId);
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