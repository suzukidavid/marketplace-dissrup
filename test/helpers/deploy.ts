import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import {Contract} from "ethers";

export async function deployMarketplace(singer: SignerWithAddress) {
    const marketplace = await ethers.getContractFactory(
        "Marketplace", 
        singer
        );
    return marketplace.deploy();
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
