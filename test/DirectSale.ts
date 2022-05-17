import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const BASIS_POINT = 100;

enum TokenStandard {
  ERC721,
  ERC1155,
}

import {
  deployMarketplace,
  deployMockAsset,
  deployMockERC1155Creator,
  deployMockERC721Creator,
} from "./helpers/deploy";

import { changedTokenBalanceInContract } from "./helpers/utils";

describe("DirectSale", function () {
  let deployer: SignerWithAddress;
  let payout: SignerWithAddress;
  let creator: SignerWithAddress;
  let collector: SignerWithAddress;
  let otherCollector: SignerWithAddress;
  let royaltyPayout: SignerWithAddress;
  let otherRoyaltyPayout: SignerWithAddress;
  let Marketplace: Contract;
  let AssetMock: Contract;
  let ERC721CreatorMock: Contract;
  let ERC1155CreatorMock: Contract;
  let UnapprovedContract: Contract;
  describe("List", function () {
    beforeEach(async function () {
      const accounts = await ethers.getSigners();
      [deployer, payout, creator, collector] = accounts;

      Marketplace = await deployMarketplace(deployer, payout);

      AssetMock = await deployMockAsset(deployer);

      ERC721CreatorMock = await deployMockERC721Creator(creator);

      ERC1155CreatorMock = await deployMockERC1155Creator(creator);

      UnapprovedContract = await deployMockERC721Creator(creator);

      await Marketplace.connect(deployer).addContractAllowlist(
        AssetMock.address,
        TokenStandard.ERC1155
      );

      await Marketplace.connect(deployer).addContractAllowlist(
        ERC721CreatorMock.address,
        TokenStandard.ERC721
      );

      await Marketplace.connect(deployer).addContractAllowlist(
        ERC1155CreatorMock.address,
        TokenStandard.ERC1155
      );
    });

    it("list Dissrup asset as direct sale", async function () {
      await AssetMock.mint(creator.address, 5, 1);

      await AssetMock.connect(deployer).addSaleRole(Marketplace.address);

      const receipt = Marketplace.connect(creator).listDirectSale(
        AssetMock.address,
        0,
        5,
        2000
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "ListDirectSale")
        .withArgs(1, AssetMock.address, 0, creator.address, 5, 2000);
    });

    it("list Manifold ERC721", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "ListDirectSale")
        .withArgs(1, ERC721CreatorMock.address, 1, creator.address, 1, 2000);
      const verifyChangeTokenBalances = await changedTokenBalanceInContract(
        ERC721CreatorMock,
        1,
        creator,
        [creator, Marketplace],
        [0, 1]
      );

      expect(verifyChangeTokenBalances).to.be.equal(true);
    });

    it("list Manifold ERC1155", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        [],
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        10,
        3000
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "ListDirectSale")
        .withArgs(1, ERC1155CreatorMock.address, 1, creator.address, 10, 3000);

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [0, 10]
        )
      ).to.be.true;
    });

    it("list and change price", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        1000
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "UpdateDirectSale")
        .withArgs(1, ERC721CreatorMock.address, 1, creator.address, 1, 1000);
    });

    it("list and add supply", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        5,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        10,
        2000
      );
      await expect(receipt)
        .to.be.emit(Marketplace, "UpdateDirectSale")
        .withArgs(1, ERC1155CreatorMock.address, 1, creator.address, 10, 2000);

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [0, 10]
        )
      ).to.be.true;
    });

    it("list and reduce supply", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        10,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        5,
        2000
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "UpdateDirectSale")
        .withArgs(1, ERC1155CreatorMock.address, 1, creator.address, 5, 2000);

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [5, 5]
        )
      ).to.be.true;
    });

    it("list and cancel list", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(creator).cancelDirectSale(
        ERC721CreatorMock.address,
        1,
        1
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "CancelDirectSale")
        .withArgs(ERC721CreatorMock.address, 1, 1, creator.address);

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [1, 0]
        )
      ).to.be.true;
    });

    it("cannot list unapproved asset", async function () {
      await UnapprovedContract.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await UnapprovedContract.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        UnapprovedContract.address,
        1,
        1,
        2000
      );

      await expect(receipt).to.be.revertedWith(
        `Contract_Address_Is_Not_Approved\(\"${UnapprovedContract.address}\"`
      );

      expect(
        await changedTokenBalanceInContract(
          UnapprovedContract,
          1,
          creator,
          [creator, Marketplace],
          [1, 0]
        )
      ).to.be.true;
    });

    it("cannot list unowned asset", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(collector).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      await expect(receipt).to.be.revertedWith(
        "ERC721: transfer from incorrect owner"
      );
    });

    it("cannot list with amount zero", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        0,
        2000
      );

      await expect(receipt).to.be.revertedWith(
        "Direct_Sale_Amount_Cannot_Be_Zero()"
      );

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [10, 0]
        )
      ).to.be.true;
    });

    it("cannot list with price lower then minimum", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        10
      );

      await expect(receipt).to.be.revertedWith("Direct_Sale_Price_Too_Low()");

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [1, 0]
        )
      ).to.be.true;
    });

    it("cannot cancel unowned list", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const recepit = Marketplace.connect(collector).cancelDirectSale(
        ERC721CreatorMock.address,
        1,
        1
      );

      await expect(recepit).to.be.revertedWith(
        `Direct_Sale_Not_The_Owner\(\"${collector.address}\", \"${creator.address}\"\)`
      );

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [0, 1]
        )
      ).to.be.true;
    });

    it("cannot change price for unowned list", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).updateDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        3000
      );

      await expect(receipt).to.be.revertedWith(
        `Direct_Sale_Not_The_Owner\(\"${collector.address}\", \"${creator.address}\"\)`
      );
    });

    it("cannot list ERC721 with amount to be more then one", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      const receipt = Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        2,
        2000
      );

      await expect(receipt).to.be.revertedWith(
        "Core_Amount_Is_Not_Valid_For_ERC721()"
      );

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [1, 0]
        )
      ).to.be.true;
    });

    it("cannot change amount to be more then owned", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        5,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        15,
        2000
      );

      await expect(receipt).to.be.revertedWith(
        "ERC1155: insufficient balance for transfer"
      );

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [5, 5]
        )
      ).to.be.true;
    });

    it("cannot change amount to be zero", async function () {
      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        10,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        0,
        2000
      );

      await expect(receipt).to.be.revertedWith("Not_Valid_Params_For_Update()");

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [0, 10]
        )
      ).to.be.true;
    });

    it("cannot change price to be lower then minimum", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(creator).updateDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        20
      );

      await expect(receipt).to.be.revertedWith("Not_Valid_Params_For_Update()");

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, Marketplace],
          [0, 1]
        )
      ).to.be.true;
    });
  });

  describe("Buy", async function () {
    beforeEach(async function () {
      const accounts = await ethers.getSigners();
      [
        deployer,
        payout,
        royaltyPayout,
        otherRoyaltyPayout,
        creator,
        collector,
        otherCollector,
      ] = accounts;

      Marketplace = await deployMarketplace(deployer, payout);

      // AssetMock = await deployMockAsset(deployer);

      ERC721CreatorMock = await deployMockERC721Creator(creator);

      ERC1155CreatorMock = await deployMockERC1155Creator(creator);

      //await Marketplace.addContractAllowlist(AssetMock.address);

      await Marketplace.addContractAllowlist(
        ERC721CreatorMock.address,
        TokenStandard.ERC721
      );

      await Marketplace.addContractAllowlist(
        ERC1155CreatorMock.address,
        TokenStandard.ERC1155
      );

      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );

      await ERC721CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );

      await ERC1155CreatorMock.connect(creator).mintMock(
        creator.address,
        10,
        []
      );

      await ERC1155CreatorMock.connect(creator).setApprovalForAll(
        Marketplace.address,
        true
      );
    });

    it("buy Direct Sale", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        { value: 2000 }
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "Buy")
        .withArgs(
          ERC721CreatorMock.address,
          1,
          1,
          1,
          collector.address,
          creator.address
        );

      await expect(() => receipt).to.be.changeEtherBalances(
        [creator, payout, collector],
        [1700, 300, -2000]
      );

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, collector, Marketplace],
          [0, 1, 0]
        )
      ).to.be.true;
    });

    it("can buy with Manifold Royalties", async function () {
      await ERC721CreatorMock.connect(creator).mintBaseMock(
        creator.address,
        "https://dissrup.com"
      );
      const royaltiesPayess = [
        royaltyPayout.address,
        otherRoyaltyPayout.address,
      ];
      const royaltiesShares = [10 * BASIS_POINT, 20 * BASIS_POINT];

      await ERC721CreatorMock.connect(creator).setRoyalty(
        1,
        royaltiesPayess,
        royaltiesShares
      );

      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        10000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        { value: 10000 }
      );

      await expect(() => receipt).to.be.changeEtherBalances(
        [creator, royaltyPayout, otherRoyaltyPayout, payout, collector],
        [5500, 1000, 2000, 1500, -10000]
      );
    });

    it("buy one of many Direct Sale", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC1155CreatorMock.address,
        1,
        10,
        2000
      );

      let receipt = Marketplace.connect(collector).buyDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        5,
        { value: 2000 * 5 }
      );

      await expect(receipt)
        .to.be.emit(Marketplace, "Buy")
        .withArgs(
          ERC1155CreatorMock.address,
          1,
          1,
          5,
          collector.address,
          creator.address
        );

      await expect(() => receipt).to.be.changeEtherBalances(
        [creator, payout, collector],
        [8500, 1500, -10000]
      );

      receipt = Marketplace.connect(otherCollector).buyDirectSale(
        ERC1155CreatorMock.address,
        1,
        1,
        5,
        { value: 2000 * 5 }
      );

      await expect(receipt)
        .to.emit(Marketplace, "Buy")
        .withArgs(
          ERC1155CreatorMock.address,
          1,
          1,
          5,
          otherCollector.address,
          creator.address
        );

      expect(await receipt).to.be.changeEtherBalances(
        [creator, payout, otherCollector],
        [8500, 1500, -10000]
      );

      expect(
        await changedTokenBalanceInContract(
          ERC1155CreatorMock,
          1,
          creator,
          [creator, collector, otherCollector, Marketplace],
          [0, 5, 5, 0]
        )
      ).to.be.true;
    });

    it("buy and get refund if msg value grather then price", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        { value: 4000 }
      );

      await expect(() => receipt).to.be.changeEtherBalances(
        [creator, payout, collector],
        [1700, 300, -2000]
      );
    });

    it("cannot buy if price not enough", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        1,
        { value: 1000 }
      );

      await expect(receipt).to.be.revertedWith("Not_Enough_Ether_To_Buy()");

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, collector, Marketplace],
          [0, 0, 1]
        )
      ).to.be.true;
    });

    it("cannot buy if list not exist", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        2,
        1,
        { value: 2000 }
      );

      await expect(receipt).to.be.revertedWith("Not_A_Valid_Direct_Sale()");
    });

    it("cannot buy if amount to big", async function () {
      await Marketplace.connect(creator).listDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2000
      );

      const receipt = Marketplace.connect(collector).buyDirectSale(
        ERC721CreatorMock.address,
        1,
        1,
        2,
        { value: 2000 }
      );

      await expect(receipt).to.be.revertedWith(
        "Required_Amount_To_Big_To_Buy()"
      );

      expect(
        await changedTokenBalanceInContract(
          ERC721CreatorMock,
          1,
          creator,
          [creator, collector, Marketplace],
          [0, 0, 1]
        )
      ).to.be.true;
    });
  });
});
