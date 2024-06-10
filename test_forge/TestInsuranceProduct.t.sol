// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.20;

import {console} from "forge-std/src/Test.sol";

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {APPLIED, ACTIVE, CLOSED} from "gif-next/contracts/type/StateId.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IBundle} from "gif-next/contracts/instance/module/IBundle.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {ILifecycle} from "gif-next/contracts/shared/ILifecycle.sol";
import {IPolicy} from "gif-next/contracts/instance/module/IPolicy.sol";
import {IRisk} from "gif-next/contracts/instance/module/IRisk.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {POLICY} from "gif-next/contracts/type/ObjectType.sol";
import {PRODUCT_OWNER_ROLE, DISTRIBUTION_OWNER_ROLE, POOL_OWNER_ROLE} from "gif-next/contracts/type/RoleId.sol";
import {ReferralLib} from "gif-next/contracts/type/Referral.sol";
import {RiskId, RiskIdLib, eqRiskId} from "gif-next/contracts/type/RiskId.sol";
import {Seconds, SecondsLib} from "gif-next/contracts/type/Seconds.sol";
import {GifTest} from "gif-next/test/base/GifTest.sol";
import {Timestamp, TimestampLib, zeroTimestamp} from "gif-next/contracts/type/Timestamp.sol";
import {UFixedLib} from "gif-next/contracts/type/UFixed.sol";

import {BasicDistribution} from "../contracts/BasicDistribution.sol";
import {BasicPool} from "../contracts/BasicPool.sol";
import {InsuranceProduct} from "../contracts/InsuranceProduct.sol";



contract TestInsuranceProduct is GifTest {
    using NftIdLib for NftId;

    Seconds public sec30;

    BasicDistribution public testDistribution;
    NftId public testDistributionNftId;

    BasicPool public testPool;
    NftId public testPoolNftId;

    InsuranceProduct public testProduct;
    NftId public testProductNftId;

    function setUp() public override {
        super.setUp();
        sec30 = SecondsLib.toSeconds(30);
    }

    function test_InsuranceProduct_underwriteWithPayment() public {
        // GIVEN
        vm.startPrank(registryOwner);
        token.transfer(customer, 1000);
        vm.stopPrank();

        _prepareTestInsuranceProduct();  

        vm.startPrank(productOwner);

        // TODO: fix this
        // Fee memory productFee = FeeLib.toFee(UFixedLib.zero(), 10);
        // product.setFees(productFee, FeeLib.zeroFee());

        RiskId riskId = RiskIdLib.toRiskId("42x4711");
        bytes memory data = "bla di blubb";
        testProduct.createRisk(riskId, data);

        vm.stopPrank();

        vm.startPrank(customer);

        IComponents.ComponentInfo memory productComponentInfo = instanceReader.getComponentInfo(testProductNftId);
        token.approve(address(productComponentInfo.tokenHandler), 1000);

        NftId policyNftId = testProduct.createApplication(
            customer,
            riskId,
            AmountLib.toAmount(1000),
            SecondsLib.toSeconds(30),
            "",
            bundleNftId,
            ReferralLib.zero()
        );
        assertTrue(policyNftId.gtz(), "policyNftId was zero");
        assertEq(chainNft.ownerOf(policyNftId.toInt()), customer, "customer not owner of policyNftId");

        assertTrue(instanceReader.getPolicyState(policyNftId) == APPLIED(), "state not APPLIED");
        
        vm.stopPrank();

        // WHEN
        vm.startPrank(productOwner);
        testProduct.underwrite(policyNftId, true, TimestampLib.blockTimestamp()); 

        // THEN
        assertTrue(instanceReader.getPolicyState(policyNftId) == ACTIVE(), "policy state not UNDERWRITTEN");

        // TODO: fix this
        // IBundle.BundleInfo memory bundleInfo = instanceReader.getBundleInfo(bundleNftId);
        // assertEq(bundleInfo.lockedAmount.toInt(), 1000, "lockedAmount not 1000");
        // assertEq(bundleInfo.feeAmount.toInt(), 10, "feeAmount not 10");
        // assertEq(bundleInfo.capitalAmount.toInt(), 10000 + 100 - 10, "capitalAmount not 1100");
        
        IPolicy.PolicyInfo memory policyInfo = instanceReader.getPolicyInfo(policyNftId);
        assertTrue(policyInfo.activatedAt.gtz(), "activatedAt not set");
        assertTrue(policyInfo.expiredAt.gtz(), "expiredAt not set");
        assertTrue(policyInfo.expiredAt.toInt() == policyInfo.activatedAt.addSeconds(sec30).toInt(), "expiredAt not activatedAt + 30");

        // TODO: fix this
        // assertEq(token.balanceOf(testPproduct.getWallet()), 10, "product balance not 10");
        // assertEq(token.balanceOf(testDistribution.getWallet()), 10, "distibution balance not 10");
        // assertEq(token.balanceOf(address(customer)), 880, "customer balance not 880");
        // assertEq(token.balanceOf(testPool.getWallet()), 10100, "pool balance not 10100");

        assertEq(instanceBundleManager.activePolicies(bundleNftId), 1, "expected one active policy");
        assertTrue(instanceBundleManager.getActivePolicy(bundleNftId, 0).eq(policyNftId), "active policy nft id in bundle manager not equal to policy nft id");
    }

    function _prepareTestInsuranceProduct() internal {
        vm.startPrank(instanceOwner);
        instanceAccessManager.grantRole(PRODUCT_OWNER_ROLE().toInt(), productOwner, 0);
        instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE().toInt(), distributionOwner, 0);
        instanceAccessManager.grantRole(POOL_OWNER_ROLE().toInt(), poolOwner, 0);
        vm.stopPrank();

        vm.startPrank(distributionOwner);
        testDistribution = new BasicDistribution(
            address(registry),
            instanceNftId,
            distributionOwner,
            "BasicDistribution",
            address(token),
            "", 
            ""
        );

        testDistribution.register();
        testDistributionNftId = testDistribution.getNftId();
        vm.stopPrank();

        vm.startPrank(poolOwner);
        testPool = new BasicPool(
            address(registry),
            instanceNftId,
            "BasicPool",
            address(token),
            false,
            poolOwner,
            "",
            ""
        );
        testPool.register();
        testPoolNftId = testPool.getNftId();
        testPool.approveTokenHandler(AmountLib.max());
        vm.stopPrank();

        vm.startPrank(productOwner);
        testProduct = new InsuranceProduct(
            address(registry),
            instanceNftId,
            productOwner,
            "InsuranceProduct",
            address(token),
            false,
            address(testPool), 
            address(testDistribution),
            "",
            ""
        );
        
        testProduct.register();
        testProductNftId = testProduct.getNftId();
        vm.stopPrank();

        // TODO: fix this
        // vm.startPrank(distributionOwner);
        // Fee memory distributionFee = FeeLib.toFee(UFixedLib.zero(), 10);
        // Fee memory minDistributionOwnerFee = FeeLib.toFee(UFixedLib.zero(), 10);
        // testDistribution.setFees(minDistributionOwnerFee, distributionFee);
        // vm.stopPrank();

        // TODO: fix this
        // vm.startPrank(poolOwner);
        // Fee memory poolFee = FeeLib.toFee(UFixedLib.zero(), 10);
        // pool.setFees(poolFee, FeeLib.zeroFee(), FeeLib.zeroFee());
        // vm.stopPrank();

        vm.startPrank(registryOwner);
        token.transfer(investor, 10000);
        vm.stopPrank();

        vm.startPrank(investor);
        IComponents.ComponentInfo memory poolComponentInfo = instanceReader.getComponentInfo(testPoolNftId);
        token.approve(address(poolComponentInfo.tokenHandler), 10000);

        Fee memory bundleFee = FeeLib.toFee(UFixedLib.zero(), 10);
        bundleNftId = testPool.createBundle(
            bundleFee, 
            10000, 
            SecondsLib.toSeconds(604800), 
            ""
        );
        vm.stopPrank();
    }

}
