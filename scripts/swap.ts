import { Address, Cell, toNano } from '@ton/core';
import { Swap } from '../wrappers/Swap';
import { compile, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {

    const swap = provider.open(Swap.createFromAddress(Address.parse("EQAwOpTroDdKsGEFaRWCi81LYdt7TUeARoa97iDASRGmzx99")))

    await swap.sendSwap(provider.sender(), toNano('0.275'), toNano("0.728"));

    // run methods on `buyer`
}
