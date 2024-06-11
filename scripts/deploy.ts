import { AddressLike, Signer, encodeBytes32String } from "ethers";
import { AccessManagerExtendedInitializeable__factory, BasicDistribution, Distribution, IInstance__factory, Pool, Product } from "../typechain-types";
import { getNamedAccounts } from "./libs/accounts";
import { deployContract } from "./libs/deployment";
import { DISTRIBUTION_OWNER_ROLE, POOL_OWNER_ROLE, PRODUCT_OWNER_ROLE } from "./libs/gif_constants";
import { executeTx } from "./libs/transaction";
import { logger } from "./logger";

async function main() {
    logger.info("deploying components ...");
    const { protocolOwner, instanceOwner, distributionOwner, poolOwner, productOwner } = await getNamedAccounts();

    const amountLibAddress = process.env.AMOUNTLIB_ADDRESS;
    const feeLibAddress = process.env.FEELIB_ADDRESS;
    const nftIdLibAddress = process.env.NFTIDLIB_ADDRESS;
    const referralLibAddress = process.env.REFERRALLIB_ADDRESS;
    const roleIdLibAddress = process.env.ROLEIDLIB_ADDRESS;
    const ufixedLibAddress = process.env.UFIXEDLIB_ADDRESS;
    
    const instanceNftId = process.env.INSTANCE_NFTID;
    const instanceAddress = process.env.INSTANCE_ADDRESS;
    
    const instance = IInstance__factory.connect(instanceAddress!, instanceOwner);
    const instanceAccessManagerAddress = await instance.getInstanceAccessManager();
    const registryAddress = await instance.getRegistry();
    const instanceAccessManager = AccessManagerExtendedInitializeable__factory.connect(instanceAccessManagerAddress, instanceOwner);
    await executeTx(() => instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE, distributionOwner.address, 0));
    console.log(`Distribution owner role granted to ${distributionOwner.address} at ${instanceAccessManagerAddress}`);
    await executeTx(() => instanceAccessManager.grantRole(POOL_OWNER_ROLE, poolOwner.address, 0));
    console.log(`Pool owner role granted to ${poolOwner.address} at ${instanceAccessManagerAddress}`);
    await executeTx(() => instanceAccessManager.grantRole(PRODUCT_OWNER_ROLE, productOwner.address, 0));
    console.log(`Product owner role granted to ${productOwner.address} at ${instanceAccessManagerAddress}`);
    
    const { address: usdcMockAddress } = await deployContract(
        "UsdcMock",
        protocolOwner);

    const { distributionAddress } = await deployAndRegisterDistribution(
        distributionOwner,
        instanceNftId!,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        referralLibAddress!,
        amountLibAddress!,
    );
    const { poolAddress } = await deployAndRegisterPool(
        poolOwner,
        instanceNftId!,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        amountLibAddress!,
        feeLibAddress!,
        roleIdLibAddress!,
        ufixedLibAddress!,
    );
    await deployAndRegisterProduct(
        productOwner,
        instanceNftId!,
        usdcMockAddress,
        registryAddress!,
        poolAddress,
        distributionAddress,
        nftIdLibAddress!,
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
    amountLibAddress: AddressLike,
): Promise<{ distribution: Distribution, distributionNftId: bigint, distributionAddress: AddressLike }>  {
    const distName = "BasicDistribution-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: distAddress, contract: dist } = await deployContract(
        "BasicDistribution",
        distributionOwner,
        [
            registryAddress,
            instanceNftId,
            distributionOwner,
            distName,
            usdcMockAddress,
            encodeBytes32String(""),
            encodeBytes32String(""),
        ],
        {
            libraries: {
                AmountLib: amountLibAddress,
                NftIdLib: nftIdLibAddress,
                ReferralLib: referralLibAddress,
            }
        });

    const distribution = dist as Distribution;

    console.log(`Registering distribution ...`);
    try {
        const rcpt = await executeTx(() => distribution.register());
    } catch (error) {
        const failure = distribution.interface.parseError(error.data);
        logger.error(failure?.name);
        logger.error(failure?.args);
        throw error;
    }
    const distNftId = await distribution.getNftId();
    console.log(`Distribution ${distName} registered at ${distAddress} with ${distNftId}`);
    return {
        distribution,
        distributionNftId: distNftId,
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
): Promise<{ pool: Pool, poolNftId: bigint, poolAddress: AddressLike }> {
    const poolName = "BasicPool-" + Math.random().toString(16).substring(7);
    const { address: poolAddress, contract: poolContract } = await deployContract(
        "BasicPool",
        poolOwner,
        [
            registryAddress,
            instanceNftId,
            poolOwner,
            poolName,
            usdcMockAddress,
            false,
            encodeBytes32String(""),
            encodeBytes32String(""),
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

    var pool = poolContract as Pool;

    console.log(`Registering pool at ${poolAddress} ...`);
    const rcpt = await executeTx(() => pool.register());
    const poolNftId = await pool.getNftId();
    console.log(`Distribution ${poolName} registered at ${poolAddress} with ${poolNftId}`);
    return {
        pool,
        poolNftId,
        poolAddress,
    };
}

async function deployAndRegisterProduct(
    productOwner: Signer,
    instanceNftId: string, 
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    poolAddress: AddressLike,
    distributionAddress: AddressLike,
    nftIdLibAddress: AddressLike, 
): Promise<{ product: Product, productNftId: bigint, productAddress: AddressLike }> {
    const productName = "InsuranceProduct-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: productAddress, contract: productContract } = await deployContract(
        "InsuranceProduct",
        productOwner,
        [
            registryAddress,
            instanceNftId,
            productOwner,
            productName,
            usdcMockAddress,
            false,
            poolAddress,
            distributionAddress,
            encodeBytes32String(""),
            encodeBytes32String(""),
        ],
        {
            libraries: {
                NftIdLib: nftIdLibAddress,
            }
        });

    const product = productContract as Product;

    console.log(`Registering product at ${productAddress} ...`);
    const rcpt = await executeTx(() => product.register());
    const productNftId = await product.getNftId();
    console.log(`Product ${productName} registered at ${productAddress} with ${productNftId}`);
    return {
        product,
        productNftId,
        productAddress,
    };
}


main().catch((error) => {
    logger.error(error.stack);
    process.exit(1);
});