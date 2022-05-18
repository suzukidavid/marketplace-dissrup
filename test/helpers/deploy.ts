import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {Contract} from "ethers";
import {ethers, upgrades} from "hardhat";

export async function deployMarketplace(singer: SignerWithAddress, payout: SignerWithAddress) {
    const Marketplace = await ethers.getContractFactory(
        "Marketplace", 
        singer
        );
    return upgrades.deployProxy(Marketplace,[payout.address],{});
}

export async function deployMockAsset(singer: SignerWithAddress) {
    const assetMock = await ethers.getContractFactory(
        "AssetMock",
        singer
        );
          return assetMock.deploy("https://dissrup.com","MOCKASSET","MockAsset");
}

export async function deployMockERC721Creator(singer: SignerWithAddress) {
    const erc721CreatorMock = await ethers.getContractFactory(
        "ERC721CreatorMock",
        singer
    );
   
    return erc721CreatorMock.deploy();
   
}

export async function deployMockERC1155Creator(singer: SignerWithAddress) {
    const erc1155CreatorMock = await ethers.getContractFactory(
        "ERC1155CreatorMock",
        singer
     );   

     return erc1155CreatorMock.deploy();

}
