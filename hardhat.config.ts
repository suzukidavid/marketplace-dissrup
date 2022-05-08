import * as dotenv from "dotenv";
import {HardhatUserConfig, task} from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// task("deploy", "Deploy Marketplace")
//   .addParam("payout")
//   .addParam("dissrupAssetContract")
//   .setAction(async (taskArgs, hre) => {
//     console.log("taskArgs", taskArgs);
//     const Marketplace = await hre.ethers.getContractFactory(
//       "Marketplace"
//     );

//     const marketplace = await Marketplace.deploy(
//       taskArgs.payout,
//       dissrupAssetContract
//     );

//     console.log("marketplace deployed to:", marketplace.address);

//   });


const config: HardhatUserConfig = {
    solidity: {
      version: "0.8.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
    networks: {
      rinkeby: {
        url: process.env.RINKEBY_URL || "",
        accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      },
    },
    gasReporter: {
      enabled: process.env.REPORT_GAS !== undefined,
      coinmarketcap: process.env.COINMARKETCAP_API_KEY,
      gasPrice: 50,
      currency: "USD",
    },
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  };
  
  export default config;