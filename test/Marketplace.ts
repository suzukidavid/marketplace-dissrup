import { expect } from "chai";
import { ethers } from "hardhat";
import {Contract} from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

enum TokenStandard {ERC721, ERC1155};

import {deployMarketplace,
       deployMockERC721Creator
    } from "./helpers/deploy"

    import{createSaleERC721} from "./helpers/sales";

describe("Marketplace", function () {
    let deployer: SignerWithAddress;
    let otherAdmin: SignerWithAddress;
    let payout: SignerWithAddress;
    let otherPayout: SignerWithAddress;
    let creator: SignerWithAddress;
    let collector: SignerWithAddress;
    let Marketplace: Contract;
    let ERC721CreatorMock: Contract;
    describe("Admin", function () {
        beforeEach(async function () {

            const accounts = await ethers.getSigners();

            [deployer,otherAdmin,payout,otherPayout,creator] = accounts;

            Marketplace = await deployMarketplace(deployer,payout);

            ERC721CreatorMock = await deployMockERC721Creator(creator);

        });
        
        it("Admin can add contracts to whitelist",async function(){

            const recepit = Marketplace.addContractAllowlist(ERC721CreatorMock.address,TokenStandard.ERC721);
            await expect(recepit).to.emit(Marketplace,"RegisterContract").withArgs(ERC721CreatorMock.address,TokenStandard.ERC721)

        })

        it("can set Dissrup payment",async function(){
            
            let recepit = Marketplace.setDissrupPayment(otherPayout.address);
            await expect(recepit).to.emit(Marketplace,"SetDissrupPayment").withArgs(otherPayout.address);
            
            // verify address updated  
           recepit = createSaleERC721(Marketplace,deployer,creator,collector,2000);
           expect(recepit).to.be.changeEtherBalances([creator,otherPayout,collector],[1700,300,-2000])
        })

        it("can set admin account",async function(){
            
            let receipt = Marketplace.setAdmin(otherAdmin.address);
            await expect(receipt).to.emit(Marketplace,"SetAdmin").withArgs(otherAdmin.address);

            // verify admin prem              
            receipt = Marketplace.connect(otherAdmin).addContractAllowlist(ERC721CreatorMock.address,TokenStandard.ERC721);
            await expect(receipt).to.emit(Marketplace,"RegisterContract").withArgs(ERC721CreatorMock.address,TokenStandard.ERC721)
        })

        it("can revoke admin account",async function(){
            
            await Marketplace.connect(deployer).setAdmin(otherAdmin.address);

            let receipt = Marketplace.connect(deployer).revokeAdmin(otherAdmin.address);
            await expect(receipt).to.emit(Marketplace,"RevokeAdmin").withArgs(otherAdmin.address);
            
            receipt = Marketplace.connect(otherAdmin).addContractAllowlist(ERC721CreatorMock.address,TokenStandard.ERC721);
            await expect(receipt).to.revertedWith("Only_Admin_Can_Access()");
        })

        it("cannot add contracts to whitelist if not admin",async function(){
            
            const recepit = Marketplace.connect(creator).addContractAllowlist(ERC721CreatorMock.address,TokenStandard.ERC721);
            await expect(recepit).to.be.revertedWith("Only_Admin_Can_Access()");
        })

        it("cannot set Dissrup payment if not admin",async function(){
            
            const recepit = Marketplace.connect(creator).setDissrupPayment(creator.address);
            await expect(recepit).to.be.revertedWith("Only_Admin_Can_Access()");
        })
        it("cannot add contracts to whitelist if not admin",async function(){
            
            const recepit = Marketplace.connect(creator).setAdmin(creator.address);
            await expect(recepit).to.be.revertedWith("Only_Admin_Can_Access()");
        })
        it("cannot revoke admin account if not admin",async function(){
            
            let receipt = Marketplace.connect(creator).revokeAdmin(otherAdmin.address);
            await expect(receipt).to.revertedWith("Only_Admin_Can_Access()");            
        })

    });
})