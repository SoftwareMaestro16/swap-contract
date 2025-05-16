import { Address, Cell, toNano } from '@ton/core';
import { Swap } from '../wrappers/Swap';
import { compile, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const swap = provider.open(Swap.createFromConfig({
        contractOwner: provider.sender().address as Address,
        percentToBuy: 95n,
        minToBuy: toNano("0.499"),
        isLocked: 0n,
        poolAddress: Address.parse("EQDcm06RlreuMurm-yik9WbL6kI617B77OrSRF_ZjoCYFuny"),
        jettonVaultAddress: Address.parse("EQAf4BMoiqPf0U2ADoNiEatTemiw3UXkt5H90aQpeSKC2l7f"),
        jettonMinterAddress: Address.parse("EQBlqsm144Dq6SjbPI4jjZvA1hqTIP3CvHovbIfW_t-SCALE"),
        jettonWalletCode: Cell.fromBase64('te6cckECEgEAAygAART/APSkE/S88sgLAQIBYgIRAgLMAwYCAdQEBQC7CDHAJJfBOAB0NMDAXGwlRNfA/AL4PpA+kAx+gAxcdch+gAx+gAwAtMfghAPin6lUiC6lTE0WfAI4IIQF41FGVIgupYxREQD8AngNYIQWV8HvLqTWfAK4F8EhA/y8IAARPpEMHC68uFNgAgFIBw4CASAICgH1APTP/oA+kAh8AHtRND6APpA+kDUMFE2oVIqxwXy4sEowv/y4sJUNEJwVCATVBQDyFAE+gJYzxYBzxbMySLIywES9AD0AMsAySD5AHB0yMsCygfL/8nQBPpA9AQx+gB3gBjIywVQCM8WcPoCF8trE8yCEBeNRRnIyx8ZgCQCayz9QB/oCIs8WUAbPFiX6AlADzxbJUAXMI5FykXHiUAioE6CCCJiWgKoAggiYloCgoBS88uLFBMmAQPsAECPIUAT6AljPFgHPFszJ7VQD9ztRND6APpA+kDUMAjTP/oAUVGgBfpA+kBTW8cFVHNtcFQgE1QUA8hQBPoCWM8WAc8WzMkiyMsBEvQA9ADLAMn5AHB0yMsCygfL/8nQUA3HBRyx8uLDCvoAUaihggiYloCCCJiWgBK2CKGCCJiWgKAYoSfjDyXXCwHDACOALDA0AcFJ5oBihghBzYtCcyMsfUjDLP1j6AlAHzxZQB88WyXGAGMjLBSTPFlAG+gIVy2oUzMlx+wAQJBAjAA4QSRA4N18EAHbCALCOIYIQ1TJ223CAEMjLBVAIzxZQBPoCFstqEssfEss/yXL7AJM1bCHiA8hQBPoCWM8WAc8WzMntVAIBIA8QANs7UTQ+gD6QPpA1DAH0z/6APpAMFFRoVJJxwXy4sEnwv/y4sKCCJiWgKoAFqAWvPLiw4IQe92X3sjLHxXLP1AD+gIizxYBzxbJcYAYyMsFJM8WcPoCy2rMyYBA+wBAE8hQBPoCWM8WAc8WzMntVIACDIAg1yHtRND6APpA+kDUMATTH4IQF41FGVIguoIQe92X3hO6ErHy4sXTPzH6ADAToFAjyFAE+gJYzxYBzxbMye1UgABug9gXaiaH0AfSB9IGoYa5Hhqc='),    
    }, await compile('Swap')));

    await swap.sendDeploy(provider.sender(), toNano('0.5'));

    await provider.waitForDeploy(swap.address);

    // run methods on `swap`
}
