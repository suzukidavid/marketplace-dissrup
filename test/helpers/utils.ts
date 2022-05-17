import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

export async function isOwnerOfToken(AssetContract: Contract, singer: string, tokenId: number) {
    return await AssetContract.ownerOf(tokenId) == singer;
}

export async function changedTokenBalanceInContract(AssetContract: Contract, tokenId: number, creator: SignerWithAddress, accounts: any[], owned: number[]) {
    if (accounts.length !== owned.length) {
        throw new Error("accounts & balance are not the same length!");
    }

    for (let i = 0; i < accounts.length; i++) {
        let account = accounts[i].address;
        let amount = owned[i];

        let ownedAmount = await AssetContract.connect(creator).getTokenBalance(account, tokenId);

        if (ownedAmount != amount) {

            throw new Error(formatExeption(account,amount,ownedAmount));
        }
    }
    return true;
}


function formatExeption(account: any,amount:number, ownedAmount: number){
    return(
                `Expected ${account} to own \n` +
                '\x1b[34m' +
                "\t + expected" +
                "  " +
                '\x1b[33m' +
                " - actual \n \n" +
                `\t - "${ownedAmount}" \n` +
                '\x1b[34m' +
                `\t + "${amount}"` +
                '\x1b[0m' +
                "\n\n"
    )
}