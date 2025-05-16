import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Cell, toNano } from '@ton/core';
import { Swap } from '../wrappers/Swap';
import '@ton/test-utils';
import { compile } from '@ton/blueprint';

describe('Swap', () => {
    let code: Cell;

    beforeAll(async () => {
        code = await compile('Swap');
    });

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let swap: SandboxContract<Swap>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        swap = blockchain.openContract(Swap.createFromConfig({}, code));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await swap.sendDeploy(deployer.getSender(), toNano('0.05'));

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: swap.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and swap are ready to use
    });
});
