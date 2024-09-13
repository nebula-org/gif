// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {APPLIED, COLLATERALIZED} from "gif-next/contracts/type/StateId.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {IPolicy} from "gif-next/contracts/instance/module/IPolicy.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {ReferralLib} from "gif-next/contracts/type/Referral.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {Seconds, SecondsLib} from "gif-next/contracts/type/Seconds.sol";
import {GifTest} from "gif-next/test/base/GifTest.sol";
import {TimestampLib} from "gif-next/contracts/type/Timestamp.sol";
import {UFixedLib} from "gif-next/contracts/type/UFixed.sol";

import {BasicDistributionAuthorization} from "gif-next/contracts/distribution/BasicDistributionAuthorization.sol";
import {BasicPoolAuthorization} from "gif-next/contracts/pool/BasicPoolAuthorization.sol";
import {BasicProductAuthorization} from "gif-next/contracts/product/BasicProductAuthorization.sol";

import {MyDistribution} from "../contracts/MyDistribution.sol";
import {MyPool} from "../contracts/MyPool.sol";
import {MyProduct} from "../contracts/MyProduct.sol";


// solhint-disable func-name-mixedcase
contract TestInsuranceProduct is GifTest {
    using NftIdLib for NftId;

    Seconds public sec30;

    MyDistribution public testDistribution;
    NftId public testDistributionNftId;

    MyPool public testPool;
    NftId public testPoolNftId;

    MyProduct public testProduct;
    NftId public testProductNftId;

    function setUp() public override {
        super.setUp();
        sec30 = SecondsLib.toSeconds(30);
    }

    function test_MyProduct_underwriteWithPayment() public {
        // GIVEN
        vm.startPrank(registryOwner);
        token.transfer(customer, 1000);
        vm.stopPrank();

        _prepareTestInsuranceProduct();  

        vm.startPrank(productOwner);
        RiskId riskId = testProduct.createRisk("Risk_42", "");

        vm.stopPrank();

        vm.startPrank(customer);

        IComponents.ComponentInfo memory productComponentInfo = instanceReader.getComponentInfo(testProductNftId);
        token.approve(address(productComponentInfo.tokenHandler), 1000);

        NftId policyNftId = testProduct.createApplication(
            customer,
            riskId,
            1000,
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
        testProduct.createPolicy(policyNftId, true, TimestampLib.current(), AmountLib.max()); 

        // THEN
        assertTrue(instanceReader.getPolicyState(policyNftId) == COLLATERALIZED(), "policy state not COLLATERALIZED");

        assertEq(instanceReader.getLockedAmount(bundleNftId).toInt(), 1000, "lockedAmount not 1000");
        assertEq(instanceReader.getFeeAmount(bundleNftId).toInt(), 10, "feeAmount not 10");
        assertEq(instanceReader.getBalanceAmount(bundleNftId).toInt(), 10000 + 100 + 10, "balance not 1100");

        assertEq(token.balanceOf(address(customer)), 890, "customer balance not 880");
        assertEq(token.balanceOf(testPool.getWallet()), 10110, "pool balance not 10100");

        IPolicy.PolicyInfo memory policyInfo = instanceReader.getPolicyInfo(policyNftId);
        assertTrue(policyInfo.activatedAt.gtz(), "activatedAt not set");
        assertTrue(policyInfo.expiredAt.gtz(), "expiredAt not set");
        assertTrue(policyInfo.expiredAt.toInt() == policyInfo.activatedAt.addSeconds(sec30).toInt(), "expiredAt not activatedAt + 30");

        assertEq(instanceBundleSet.activePolicies(bundleNftId), 1, "expected one active policy");
        assertTrue(instanceBundleSet.getActivePolicy(bundleNftId, 0).eq(policyNftId), "active policy nft id in bundle manager not equal to policy nft id");
    }

    function _prepareTestInsuranceProduct() internal {
        
        vm.startPrank(productOwner);
        testProduct = new MyProduct();
        testProduct.initialize(
            address(registry),
            instanceNftId,
            "MyProduct",
            new BasicProductAuthorization("MyProduct"),
            productOwner
        );
        vm.stopPrank();

        vm.startPrank(instanceOwner);
        instance.registerProduct(address(testProduct), address(token));
        testProductNftId = testProduct.getNftId();
        vm.stopPrank();

        vm.startPrank(distributionOwner);
        testDistribution = new MyDistribution();
        testDistribution.initialize(
            address(registry),
            testProductNftId,
            new BasicDistributionAuthorization("MyDistribution"),
            distributionOwner,
            "MyDistribution"
        );
        vm.stopPrank();

        vm.startPrank(productOwner);
        testProduct.registerComponent(address(testDistribution));
        testDistributionNftId = testDistribution.getNftId();
        vm.stopPrank();

        vm.startPrank(poolOwner);
        testPool = new MyPool();
        testPool.initialize(
            address(registry),
            testProductNftId,
            new BasicPoolAuthorization("MyPool"),
            poolOwner,
            "MyPool"
        );
        vm.stopPrank();

        vm.startPrank(productOwner);
        testProduct.registerComponent(address(testPool));
        testPoolNftId = testPool.getNftId();
        vm.stopPrank();

        vm.startPrank(poolOwner);
        testPool.approveTokenHandler(token, AmountLib.max());
        vm.stopPrank();

        vm.startPrank(registryOwner);
        token.transfer(investor, 10000);
        vm.stopPrank();

        vm.startPrank(investor);
        IComponents.ComponentInfo memory poolComponentInfo = instanceReader.getComponentInfo(testPoolNftId);
        token.approve(address(poolComponentInfo.tokenHandler), 10000);

        Fee memory bundleFee = FeeLib.toFee(UFixedLib.zero(), 10);
        bundleNftId = testPool.createBundle(
            investor,
            bundleFee, 
            10000, 
            SecondsLib.toSeconds(604800), 
            ""
        );
        vm.stopPrank();
    }

}
