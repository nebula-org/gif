import { AddressLike, Signer, resolveAddress } from "ethers";
import { DistributionService__factory, PoolService__factory, Registry__factory, TokenRegistry__factory } from "../lib/gif-next/typechain-types";
import { Distribution, IInstance__factory, InstanceAccessManager__factory, Pool, Pool } from "../typechain-types";
import { getNamedAccounts } from "./libs/accounts";
import { deployContract } from "./libs/deployment";
import { executeTx, getFieldFromTxRcptLogs } from "./libs/transaction";
import { logger } from "./logger";

async function main() {
    logger.info("deploying components ...");
    const { protocolOwner, instanceOwner, distributionOwner, poolOwner, productOwner } = await getNamedAccounts();

    const DISTRIBUTION_OWNER_ROLE = 2;
    const POOL_OWNER_ROLE = 4;

    const amountLibAddress = process.env.AMOUNTLIB_ADDRESS;
    const feeLibAddress = process.env.FEELIB_ADDRESS;
    const nftIdLibAddress = process.env.NFTIDLIB_ADDRESS;
    const referralLibAddress = process.env.REFERRALLIB_ADDRESS;
    const roleIdLibAddress = process.env.ROLEIDLIB_ADDRESS;
    const ufixedLibAddress = process.env.UFIXEDLIB_ADDRESS;
    
    const registryAddress = process.env.REGISTRY_ADDRESS;
    const instanceNftId = process.env.INSTANCE_NFTID;
    const instanceAddress = process.env.INSTANCE_ADDRESS;
    // const tokenRegistryAddress = process.env.TOKEN_REGISTRY_ADDRESS;
    
    const instance = IInstance__factory.connect(instanceAddress!, instanceOwner);
    const instanceAccessManagerAddress = await instance.getInstanceAccessManager();
    const instanceAccessManager = InstanceAccessManager__factory.connect(instanceAccessManagerAddress, instanceOwner);
    await executeTx(() => instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE, distributionOwner));
    await executeTx(() => instanceAccessManager.grantRole(POOL_OWNER_ROLE, poolOwner));
    console.log(`Distribution owner role granted to ${distributionOwner} at ${instanceAccessManagerAddress}`);

    const { address: usdcMockAddress } = await deployContract(
        "UsdcMock",
        protocolOwner);

    await deployAndRegisterDistribution(
        distributionOwner,
        instanceNftId!,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        referralLibAddress!
    );
    await deployAndRegisterPool(
        poolOwner,
        instanceNftId!,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        amountLibAddress,
        feeLibAddress,
        roleIdLibAddress,
        ufixedLibAddress,
    );
    
    // workaround to get script to stop
    process.exit(0);
}

async function deployAndRegisterDistribution(
    distributionOwner: Signer,
    instanceNftId: string, 
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    nftIdLibAddress: AddressLike, 
    referralLibAddress: AddressLike, 
): Promise<{ distribution: Distribution, distributionNftId: string, distributionAddress: AddressLike }>  {
    const distName = "BasicDistribution-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: distAddress, contract: dist } = await deployContract(
        "BasicDistribution",
        distributionOwner,
        [
            distName,
            registryAddress,
            instanceNftId,
            usdcMockAddress,
            fee,
            fee,
            distributionOwner
        ],
        {
            libraries: {
                NftIdLib: nftIdLibAddress,
                ReferralLib: referralLibAddress,
            }
        });

    const registry = Registry__factory.connect(await resolveAddress(registryAddress), distributionOwner);
    const distributuonServiceAddress = await registry.getServiceAddress(120, 3);
    const distributionService = DistributionService__factory.connect(distributuonServiceAddress, distributionOwner);

    console.log(`Registering distribution at ${distAddress} ...`);
    const rcpt = await executeTx(() => distributionService.register(distAddress));
    const distNftId = getFieldFromTxRcptLogs(rcpt!, registry.interface, "LogRegistration", "nftId");
    console.log(`Distribution ${distName} registered at ${distAddress} with ${distNftId}`);
    return {
        distribution: dist as Distribution,
        distributionNftId: distNftId as string,
        distributionAddress: distAddress,
    };
}

async function deployAndRegisterPool(
    poolOwner: Signer,
    instanceNftId: string, 
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    nftIdLibAddress: AddressLike, 
    amountLibAddress: AddressLike,
    feeLibAddress: AddressLike,
    roleIdLibAddress: AddressLike,
    ufixedLibAddress: AddressLike,
): Promise<{ pool: Pool, poolNftId: string, poolAddress: AddressLike }> {
    const poolName = "BasicPool-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: poolAddress, contract: pool } = await deployContract(
        "BasicPool",
        poolOwner,
        [
            poolName,
            registryAddress,
            instanceNftId,
            usdcMockAddress,
            false,
            poolOwner
        ],
        {
            libraries: {
                NftIdLib: nftIdLibAddress,
                AmountLib: amountLibAddress,
                FeeLib: feeLibAddress,
                RoleIdLib: roleIdLibAddress,
                UFixedLib: ufixedLibAddress,
            }
        });

    const registry = Registry__factory.connect(await resolveAddress(registryAddress), poolOwner);
    const poolServiceAddress = await registry.getServiceAddress(140, 3);
    const poolService = PoolService__factory.connect(poolServiceAddress, poolOwner);

    console.log(`Registering pool at ${poolAddress} ...`);
    const rcpt = await executeTx(() => poolService.register(poolAddress));
    const poolNftId = getFieldFromTxRcptLogs(rcpt!, registry.interface, "LogRegistration", "nftId");
    console.log(`Distribution ${poolName} registered at ${poolAddress} with ${poolNftId}`);
    return {
        pool: pool as Pool,
        poolNftId: poolNftId as string,
        poolAddress,
    };
}


main().catch((error) => {
    logger.error(error.stack);
    process.exit(1);
});