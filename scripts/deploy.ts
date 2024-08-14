import { AddressLike, Signer, encodeBytes32String, resolveAddress } from "ethers";
import { BasicDistribution, Distribution, IInstance, IInstance__factory, IInstanceService__factory, MyDistribution, MyPool, MyProduct, MyProduct__factory, Pool, Product } from "../typechain-types";
import { getNamedAccounts } from "./libs/accounts";
import { deployContract } from "./libs/deployment";
import { DISTRIBUTION_OWNER_ROLE, POOL_OWNER_ROLE, PRODUCT_OWNER_ROLE } from "./libs/gif_constants";
import { executeTx, getFieldFromLogs } from "./libs/transaction";
import { logger } from "./logger";
import { exceptions } from "winston";

async function main() {
    logger.info("deploying components ...");
    const { protocolOwner, instanceOwner, productOwner } = await getNamedAccounts();

    const amountLibAddress = process.env.AMOUNTLIB_ADDRESS;
    const contractLibAddress = process.env.CONTRACTLIB_ADDRESS
    const feeLibAddress = process.env.FEELIB_ADDRESS;
    const nftIdLibAddress = process.env.NFTIDLIB_ADDRESS;
    const referralLibAddress = process.env.REFERRALLIB_ADDRESS;
    const roleIdLibAddress = process.env.ROLEIDLIB_ADDRESS;
    const selectorLibAddress = process.env.SELECTORLIB_ADDRESS;
    const strLibAddress = process.env.STRLIB_ADDRESS;
    const timestampLibAddress = process.env.TIMESTAMPLIB_ADDRESS;
    const ufixedLibAddress = process.env.UFIXEDLIB_ADDRESS;
    const versionPartLibAddress = process.env.VERSIONPARTLIB_ADDRESS
    
    // const instanceNftId = process.env.INSTANCE_NFT_ID;
    const instanceServiceAddress = process.env.INSTANCE_SERVICE_ADDRESS;
    
    const instanceService = IInstanceService__factory.connect(instanceServiceAddress!, productOwner);
    const instanceCreateTx = await executeTx(
        async() => await instanceService.createInstance(),
        "createinstance tx",
        [instanceService.interface]);

    const instanceAddress = getFieldFromLogs(instanceCreateTx.logs, instanceService.interface, "LogInstanceCloned", "instance") as string;
    const instanceNftId = getFieldFromLogs(instanceCreateTx.logs, instanceService.interface, "LogInstanceCloned", "instanceNftId") as string;

    logger.info(`Instance created at ${instanceAddress} with NFT ID ${instanceNftId}`);
    
    const instance = IInstance__factory.connect(instanceAddress, productOwner);
    const registryAddress = await instance.getRegistry();
    
    const { address: usdcMockAddress } = await deployContract(
        "UsdcMock",
        protocolOwner);

    const { product, productNftId } = await deployAndRegisterProduct(
        instance,
        productOwner,
        instanceNftId,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        amountLibAddress!,
        feeLibAddress!,
        roleIdLibAddress!,
        selectorLibAddress!,
        strLibAddress!,
        timestampLibAddress!,
        versionPartLibAddress!,
        contractLibAddress!,
    );
    

    await deployAndRegisterDistribution(
        productOwner,
        productNftId.toString(),
        product,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        referralLibAddress!,
        amountLibAddress!,
        roleIdLibAddress!,
        selectorLibAddress!,
        strLibAddress!,
        timestampLibAddress!,
        versionPartLibAddress!,
    );
    await deployAndRegisterPool(
        productOwner,
        productNftId.toString(),
        product,
        usdcMockAddress,
        registryAddress!,
        nftIdLibAddress!,
        amountLibAddress!,
        feeLibAddress!,
        roleIdLibAddress!,
        ufixedLibAddress!,
        selectorLibAddress!,
        strLibAddress!,
        timestampLibAddress!,
        versionPartLibAddress!,
    );
    
    // workaround to get script to stop
    process.exit(0);
}

async function deployAndRegisterDistribution(
    distributionOwner: Signer,
    productNftId: string, 
    product: Product,
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    nftIdLibAddress: AddressLike, 
    referralLibAddress: AddressLike, 
    amountLibAddress: AddressLike,
    roleIdLibAddress: AddressLike,
    selectorLibAddress: AddressLike,
    strLibAddress: AddressLike,
    timestampLibAddress: AddressLike,
    versionPartLibAddress: AddressLike,
): Promise<{ distribution: Distribution, distributionNftId: bigint, distributionAddress: AddressLike }>  {
    const distName = "MyDistribution-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: authAddr } = await deployContract(
        "BasicDistributionAuthorization",
        distributionOwner,
        [ distName ],
        {
            libraries: {
                RoleIdLib: roleIdLibAddress,
                SelectorLib: selectorLibAddress,
                StrLib: strLibAddress,
                TimestampLib: timestampLibAddress,
                VersionPartLib: versionPartLibAddress,
            }
        });
    const { address: distAddress, contract: dist } = await deployContract(
        "MyDistribution",
        distributionOwner,
        [ ],
        {
            libraries: {
                AmountLib: amountLibAddress,
                NftIdLib: nftIdLibAddress,
                ReferralLib: referralLibAddress,
            }
        });

    const distribution = dist as MyDistribution;

    await executeTx(() => distribution.initialize(
        registryAddress,
        productNftId,
        authAddr,
        distributionOwner,
        distName,
        usdcMockAddress
    ), null, [distribution.interface]);

    console.log(`Registering distribution ...`);
    const rcpt = await executeTx(() => product.registerComponent(distAddress), null, [distribution.interface]);
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
    productNftId: string, 
    product: Product,
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    nftIdLibAddress: AddressLike, 
    amountLibAddress: AddressLike,
    feeLibAddress: AddressLike,
    roleIdLibAddress: AddressLike,
    ufixedLibAddress: AddressLike,
    selectorLibAddress: AddressLike,
    strLibAddress: AddressLike,
    timestampLibAddress: AddressLike,
    versionPartLibAddress: AddressLike,
): Promise<{ pool: Pool, poolNftId: bigint, poolAddress: AddressLike }> {
    const poolName = "MyPool-" + Math.random().toString(16).substring(7);
    const { address: authAddr } = await deployContract(
        "BasicPoolAuthorization",
        poolOwner,
        [ poolName ],
        {
            libraries: {
                RoleIdLib: roleIdLibAddress,
                SelectorLib: selectorLibAddress,
                StrLib: strLibAddress,
                TimestampLib: timestampLibAddress,
                VersionPartLib: versionPartLibAddress,
            }
        });
    const { address: poolAddress, contract: poolContract } = await deployContract(
        "MyPool",
        poolOwner,
        [],
        {
            libraries: {
                NftIdLib: nftIdLibAddress,
                AmountLib: amountLibAddress,
                FeeLib: feeLibAddress,
                RoleIdLib: roleIdLibAddress,
                UFixedLib: ufixedLibAddress,
            }
        });

    var pool = poolContract as MyPool;

    await executeTx(() => pool.initialize(
        registryAddress,
        productNftId,
        usdcMockAddress,
        authAddr,
        poolOwner,
        poolName
    ), null, [pool.interface]);

    console.log(`Registering pool at ${poolAddress} ...`);
    const rcpt = await executeTx(() => product.registerComponent(poolAddress), null, [product.interface]);
    const poolNftId = await pool.getNftId();
    console.log(`Distribution ${poolName} registered at ${poolAddress} with ${poolNftId}`);
    return {
        pool,
        poolNftId,
        poolAddress,
    };
}

async function deployAndRegisterProduct(
    instance: IInstance,
    productOwner: Signer,
    instanceNftId: string, 
    usdcMockAddress: AddressLike,
    registryAddress: AddressLike, 
    nftIdLibAddress: AddressLike, 
    amountLibAddress: AddressLike,
    feeLibAddress: AddressLike,
    roleIdLibAddress: AddressLike,
    selectorLibAddress: AddressLike,
    strLibAddress: AddressLike,
    timestampLibAddress: AddressLike,
    versionPartLibAddress: AddressLike,
    contractLibAddress: AddressLike,
): Promise<{ product: Product, productNftId: bigint, productAddress: AddressLike }> {
    const productName = "MyProduct-" + Math.random().toString(16).substring(7);
    const fee = {
        fractionalFee: 0,
        fixedFee: 0,
    };
    const { address: authAddr } = await deployContract(
        "BasicProductAuthorization",
        productOwner,
        [ productName ],
        {
            libraries: {
                RoleIdLib: roleIdLibAddress,
                SelectorLib: selectorLibAddress,
                StrLib: strLibAddress,
                TimestampLib: timestampLibAddress,
                VersionPartLib: versionPartLibAddress,
            }
        });
    const { address: productAddress, contract: productContract } = await deployContract(
        "MyProduct",
        productOwner,
        [],
        {
            libraries: {
                AmountLib: amountLibAddress,
                ContractLib: contractLibAddress,
                FeeLib: feeLibAddress,
                NftIdLib: nftIdLibAddress,
                VersionPartLib: versionPartLibAddress,
            }
        });

    const product = MyProduct__factory.connect(await resolveAddress(productAddress), productOwner);

    await executeTx(() => product.initialize(
        registryAddress,
        instanceNftId,
        productName,
        authAddr,
        usdcMockAddress,
        productOwner
    ), "init product", [product.interface]);

    console.log(`Registering product at ${productAddress} ...`);
    const rcpt = await executeTx(
        async () => await instance.registerProduct(productAddress), 
        "register product", 
        [IInstance__factory.createInterface()]);
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
    logger.error(error.data);
    process.exit(1);
});