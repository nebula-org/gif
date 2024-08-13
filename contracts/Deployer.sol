// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {MyDistribution} from "./MyDistribution.sol";
import {MyPool} from "./MyPool.sol";
import {ChainNft} from "gif-next/contracts/registry/ChainNft.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {IInstance} from "gif-next/contracts/instance/Instance.sol";
import {IInstanceService} from "gif-next/contracts/instance/IInstanceService.sol";
import {IRegistry} from "gif-next/contracts/registry/IRegistry.sol";
import {InstanceReader} from "gif-next/contracts/instance/InstanceReader.sol";
import {MyProduct} from "./MyProduct.sol";
import {INSTANCE} from "gif-next/contracts/type/ObjectType.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {ReferralLib} from "gif-next/contracts/type/Referral.sol";
import {RiskId, RiskIdLib} from "gif-next/contracts/type/RiskId.sol";
import {SecondsLib} from "gif-next/contracts/type/Seconds.sol";
import {StateId} from "gif-next/contracts/type/StateId.sol";
import {TimestampLib} from "gif-next/contracts/type/Timestamp.sol";
import {UFixedLib} from "gif-next/contracts/type/UFixed.sol";
import {UsdcMock} from "./UsdcMock.sol";
import {VersionPart} from "gif-next/contracts/type/Version.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {BasicDistributionAuthorization} from "gif-next/contracts/distribution/BasicDistributionAuthorization.sol";
import {BasicPoolAuthorization} from "gif-next/contracts/pool/BasicPoolAuthorization.sol";
import {BasicProductAuthorization} from "gif-next/contracts/product/BasicProductAuthorization.sol";

contract Deployer  {

    IRegistry private registry;
    IInstance private instance;
    NftId private instanceNftId;
    InstanceReader private instanceReader;
    UsdcMock private usdc;
    MyDistribution private distribution;
    MyPool private pool;
    MyProduct private product;
    NftId private bundleNftId;
    RiskId private riskId;
    // TODO deployer is 35k now -> product implementation specific authorizations may not fit???
    constructor(
        address registryAddress,
        address distributionAddress,
        address poolAddress,
        address productAddress,
        string memory deploymentId
    ) 
    {
        // fetch required components
        address theAllmighty = msg.sender;
        registry = IRegistry(registryAddress);
        IInstanceService instanceService = IInstanceService(registry.getServiceAddress(INSTANCE(), VersionPart.wrap(3)));
        (instance, instanceNftId) = instanceService.createInstance();
        ChainNft chainNft = ChainNft(registry.getChainNftAddress());
        instanceReader = instance.getInstanceReader();

        Fee memory bundleFee = FeeLib.toFee(UFixedLib.zero(), 0);

        // deploy token and components
        usdc = new UsdcMock();

        IAuthorization productAuth = new BasicProductAuthorization(string.concat("MyProduct", deploymentId));
        product = MyProduct(productAddress);
        product.initialize(
            registryAddress, 
            instanceNftId, 
            string.concat("MyProduct", deploymentId),
            address(usdc),
            _getSimpleProductInfo(),
            productAuth,
            address(this)
            );
        instance.registerProduct(address(product));


        IAuthorization distributionAuth = new BasicDistributionAuthorization(string.concat("MyDistribution", deploymentId));
        distribution = MyDistribution(distributionAddress);
        distribution.initialize(
            registryAddress, 
            instanceNftId, 
            distributionAuth, 
            address(this),
            string.concat("MyDistribution", deploymentId), 
            address(usdc));
        product.registerComponent(address(distribution));


        IAuthorization poolAuth = new BasicPoolAuthorization(string.concat("MyPool", deploymentId));
        pool = MyPool(poolAddress);
        pool.initialize(
            registryAddress, 
            getProductNftId(), 
            address(usdc),
            _getDefaultSimplePoolInfo(),
            poolAuth,
            address(this),
            string.concat("MyPool", deploymentId)
            );
        product.registerComponent(address(pool));
        pool.approveTokenHandler(usdc, AmountLib.max());



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

    function getInstance() public view returns (IInstance) {
        return instance;
    }

    function getInstanceNftId() public view returns (NftId) {
        return instanceNftId;
    }

    function getUsdc() public view returns (UsdcMock) {
        return usdc;
    }

    function getDistributionNftId() public view returns (NftId) {
        return distribution.getNftId();
    }

    function getDistribution() public view returns (MyDistribution) {
        return distribution;
    }

    function getPoolNftId() public view returns (NftId) {
        return pool.getNftId();
    }

    function getPool() public view returns (MyPool) {
        return pool;
    }

    function getPoolTokenHandler() public view returns (address) {
        IComponents.ComponentInfo memory poolComponentInfo = instanceReader.getComponentInfo(getPoolNftId());
        return address(poolComponentInfo.tokenHandler);
    }

    function getProductNftId() public view returns (NftId) {
        return product.getNftId();
    }

    function getProduct() public view returns (MyProduct) {
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
            amount,
            SecondsLib.toSeconds(lifetimeInDays * 24 * 60 * 60),
            "",
            bundleNftId,
            ReferralLib.zero()
        );
    }

    function underwritePolicy(NftId policyNftId) public {
        product.createPolicy(policyNftId, true, TimestampLib.blockTimestamp());
    }

    function getPolicyState(NftId policyNftId) public view returns (StateId) {
        return instanceReader.getPolicyState(policyNftId);
    }

    function getBundleBalance(NftId bundleNftId) public view returns (uint256) {
        return instanceReader.getBalanceAmount(bundleNftId).toInt();
    }

    function _getSimpleProductInfo()
        internal
        view
        returns (IComponents.ProductInfo memory productInfo)
    {
        return IComponents.ProductInfo({
            isProcessingFundedClaims: false,
            isInterceptingPolicyTransfers: false,
            hasDistribution: true,
            expectedNumberOfOracles: 1,
            numberOfOracles: 0,
            poolNftId: NftIdLib.zero(),
            distributionNftId: NftIdLib.zero(),
            oracleNftId: new NftId[](1),
            productFee: FeeLib.zero(),
            processingFee: FeeLib.zero(),
            distributionFee: FeeLib.zero(),
            minDistributionOwnerFee: FeeLib.zero(),
            poolFee: FeeLib.zero(),
            stakingFee: FeeLib.zero(),
            performanceFee: FeeLib.zero()
        });
    }

    function _getDefaultSimplePoolInfo() internal pure returns (IComponents.PoolInfo memory) {
        return IComponents.PoolInfo({
            maxBalanceAmount: AmountLib.max(),
            isInterceptingBundleTransfers: false,
            isProcessingConfirmedClaims: false,
            isExternallyManaged: false,
            isVerifyingApplications: false,
            collateralizationLevel: UFixedLib.one(),
            retentionLevel: UFixedLib.one()});
    }


}
