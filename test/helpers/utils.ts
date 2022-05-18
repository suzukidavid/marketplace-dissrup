import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

interface CheckTokenBalancesInput {
  assetContract: Contract;
  tokenId: number;
  accounts: any[];
  expectAmounts: number[];
}

export async function checkTokenBalances({
  assetContract,
  tokenId,
  accounts,
  expectAmounts,
}: CheckTokenBalancesInput) {
  if (accounts.length !== expectAmounts.length) {
    throw new Error("accounts & balance are not the same length!");
  }

  for (let i = 0; i < accounts.length; i++) {
    let account = accounts[i].address;
    let amount = expectAmounts[i];

    let ownedAmount = await assetContract.getTokenBalance(account, tokenId);

    if (ownedAmount != amount) {
      throw new Error(formatExeption(account, amount, ownedAmount));
    }
  }
  return true;
}

function formatExeption(
  account: any,
  expectAmounts: number,
  ownedAmount: number
) {
  return (
    `Expected ${account} to own \n` +
    "\x1b[34m" +
    "\t + expected" +
    "  " +
    "\x1b[33m" +
    " - actual \n \n" +
    `\t - "${ownedAmount}" \n` +
    "\x1b[34m" +
    `\t + "${expectAmounts}"` +
    "\x1b[0m" +
    "\n\n"
  );
}
