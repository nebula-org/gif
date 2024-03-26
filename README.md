# Example GIF-next Project

This repository contains example components for a GIF-next project. 
There are the `contracts/BasicDistribution.sol`, `contracts/BasicPool.sol` and `contracts/InsuranceProduct.sol` contracts. 
None if them do more then expose the internal funtions right now, but they can be used as a basis to build own components. 

The project also contains an example foundry forge based unit test `TestInsuranceProduct.t.sol` which demonstrates how to write a test for the `InsuranceProduct` contract.

## Commands

### Compiling

Compiling can be done through foundry forge as well as hardhat. 

```bash
forge compile
```

```bash
npm run build
```

### Run tests

Since the example tests are written using forge, they must be run using the forge test command. 

```bash
forge test
```

### Deployment

The deployment script `scripts/deploy.ts` is hardhat based and run using the command

```bash
npm run scripts/deploy.ts
```

As a prerequisite, the GIF framework is required to be deployed on the chain and a (new) instance created (see [this script](https://github.com/etherisc/gif-next/blob/develop/scripts/deploy_all.ts) for deployment of the GIF). 
Also these environment variables must be set (e.g. in a `.env` file):

- `AMOUNTLIB_ADDRESS` is the address of the AmountLib contract
- `FEELIB_ADDRESS` is the address of the FeeLib contract
- `NFTIDLIB_ADDRESS` is the address of the NftIdLib contract
- `REFERRALLIB_ADDRESS` is the address of the ReferralLib contract
- `ROLEIDLIB_ADDRESS` is the address of the RoleIdLib contract
- `UFIXEDLIB_ADDRESS` is the address of the UFixedLib contract
- `INSTANCE_ADDRESS` is the address of the Gif instance to register the components to
- `INSTANCE_NFTID` is the nftId of the Gif instance

The values can be takes from the output of the deployment of the GIF framework.

To deploy to a different chain, configure it in `hardhat.config.ts` and run the deployment script with the `--network` flag. 

