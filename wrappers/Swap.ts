import { Address, beginCell, Cell, Contract, contractAddress, ContractProvider, Sender, SendMode } from '@ton/core';

export type SwapConfig = {
    contractOwner: Address;
    percentToBuy: bigint;
    minToBuy: bigint;
    isLocked: bigint;
    poolAddress: Address;
    jettonVaultAddress: Address;
    jettonMinterAddress: Address;
    jettonWalletCode: Cell;
};

export function swapConfigToCell(config: SwapConfig): Cell {
    return beginCell()
        .storeAddress(config.contractOwner)
        .storeUint(config.percentToBuy, 8)
        .storeUint(config.minToBuy, 64)
        .storeUint(config.isLocked, 1)
        .storeRef(
            beginCell()
                .storeAddress(config.poolAddress)
                .storeAddress(config.jettonVaultAddress)
                .storeAddress(config.jettonMinterAddress)
                .storeRef(config.jettonWalletCode)
            .endCell()
        )
    .endCell();
}

export class Swap implements Contract {
    constructor(readonly address: Address, readonly init?: { code: Cell; data: Cell }) {}

    static createFromAddress(address: Address) {
        return new Swap(address);
    }

    static createFromConfig(config: SwapConfig, code: Cell, workchain = 0) {
        const data = swapConfigToCell(config);
        const init = { code, data };
        return new Swap(contractAddress(workchain, init), init);
    }

    async sendDeploy(provider: ContractProvider, via: Sender, value: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell().endCell(),
        });
    }

    async sendSwap(provider: ContractProvider, via: Sender, value: bigint, toSwap: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(0x10, 32)
                .storeCoins(toSwap)
            .endCell(),
        });
    }

    async sendWithdraw(provider: ContractProvider, via: Sender, value: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(0x37726bdb, 32)
            .endCell(),
        });
    }

    async sendWithdrawJettons(provider: ContractProvider, via: Sender, value: bigint, jettons: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(0x11c09682, 32)
                .storeCoins(jettons)
            .endCell(),
        });
    }
}
