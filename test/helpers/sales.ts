import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { deployMockERC721Creator } from "./deploy";
export async function createSaleERC721(Marketplace: Contract,deployer: SignerWithAddress, seller: SignerWithAddress, buyer: SignerWithAddress, price: number) {
    const ERC721CreatorMock = await deployMockERC721Creator(seller);
    ERC721CreatorMock.connect(seller).mintBaseMock(
        seller.address,
        "https://dissrup.com"
    );
    await ERC721CreatorMock.connect(seller).setApprovalForAll(
        Marketplace.address,
        true
    );
    await Marketplace.connect(deployer).addContractAllowlist(
        ERC721CreatorMock.address,
        0
    );
    await Marketplace.connect(seller).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        price
    );
    return await Marketplace.connect(buyer).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        { value: price }
    );
}