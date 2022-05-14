import { expect } from "chai";
import { ethers } from "hardhat";
import {Contract} from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {deployMarketplace,
     deployMockAsset,
      deployMockERC1155Creator,
       deployMockERC721Creator
    } from "./helpers/deploy"

describe("DirectSale", function () {
    let deployer: SignerWithAddress;
    let payout: SignerWithAddress;
    let creator: SignerWithAddress;
    let collector: SignerWithAddress;
    let Marketplace: Contract;
    let AssetMock: Contract;
    let ERC721CreatorMock: Contract;
    let ERC1155CreatorMock: Contract;
    let listedContract: Contract;
    describe("List", function () {

    beforeEach(async function () {
        const accounts = await ethers.getSigners();
        [deployer,payout,creator,collector] = accounts;
        Marketplace = await deployMarketplace(deployer); 
        AssetMock = await deployMockAsset(deployer);
        ERC721CreatorMock = await deployMockERC721Creator(creator);
        ERC1155CreatorMock = await deployMockERC1155Creator(creator);

    });
    it("list Dissrup asset as direct sale",async function(){
                
      

        await AssetMock.mint(creator.address,5,1);

        await AssetMock.connect(deployer).addSaleRole(Marketplace.address);

        const receipt = Marketplace.connect(creator).listDirectSale(AssetMock.address,0,5,2000,0);

        await expect(receipt).to.be.emit(Marketplace,"ListDirectSale").withArgs(1,AssetMock.address,0,creator.address,5,2000);

    });
    it("list Manifold ERC721", async function() {
  
        await ERC721CreatorMock.connect(creator).mintBaseMock(creator.address,"https://dissrup.com");
       
        await ERC721CreatorMock.connect(creator).setApprovalForAll(Marketplace.address,true);
       
        const receipt = Marketplace.connect(creator).listDirectSale(ERC721CreatorMock.address,1,1,2000,0);
       
        await expect(receipt)
        .to.be.emit(Marketplace,"ListDirectSale")
        .withArgs(1,ERC721CreatorMock.address,1,creator.address,1,2000);

    });
    it("list Manifold ERC1155", async function(){

         await ERC1155CreatorMock.connect(creator).mintMock(creator.address,10,[]);

        await ERC1155CreatorMock.connect(creator).setApprovalForAll(Marketplace.address,true);

        const receipt = Marketplace.connect(creator).listDirectSale(ERC1155CreatorMock.address,1,10,3000,0);

        await expect(receipt)
        .to.be.emit(Marketplace,"ListDirectSale")
        .withArgs(1,ERC1155CreatorMock.address,1,creator.address,10,3000);

    })
    it("list and change price",async function(){

        await ERC721CreatorMock.connect(creator).mintBaseMock(creator.address,"https://dissrup.com");

        await ERC721CreatorMock.connect(creator).setApprovalForAll(Marketplace.address,true);

        await Marketplace.connect(creator).listDirectSale(ERC721CreatorMock.address,1,1,2000,0);

        const receipt =  Marketplace.connect(creator).listDirectSale(ERC721CreatorMock.address,1,1,1000,1);

        await expect(receipt)
        .to.be.emit(Marketplace,"ListDirectSale")
        .withArgs(1,ERC721CreatorMock.address,1,creator.address,1,1000);

    })
    it("list and add supply", async function(){
        
        await ERC1155CreatorMock.connect(creator).mintMock(creator.address,10,[]);

        await ERC1155CreatorMock.connect(creator).setApprovalForAll(Marketplace.address,true);

        await Marketplace.connect(creator).listDirectSale(ERC1155CreatorMock.address,1,5,2000,0);

        const receipt =  Marketplace.connect(creator).listDirectSale(ERC1155CreatorMock.address,1,10,2000,1);

        await expect(receipt)
        .to.be.emit(Marketplace,"ListDirectSale")
        .withArgs(1,ERC1155CreatorMock.address,1,creator.address,10,2000);
    })
    it("list and reduce supply", async function (){

        await ERC1155CreatorMock.connect(creator).mintMock(creator.address,10,[]);

        await ERC1155CreatorMock.connect(creator).setApprovalForAll(Marketplace.address,true);

        await Marketplace.connect(creator).listDirectSale(ERC1155CreatorMock.address,1,10,2000,0);

        const receipt =  Marketplace.connect(creator).listDirectSale(ERC1155CreatorMock.address,1,5,2000,1);

        await expect(receipt)
        .to.be.emit(Marketplace,"ListDirectSale")
        .withArgs(1,ERC1155CreatorMock.address,1,creator.address,5,2000);
    })
    });
    it("cannot list unowned asset",function(){
        
    })
});