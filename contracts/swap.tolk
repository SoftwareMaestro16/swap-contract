import "updlib.tolk"
import "op-codes.tolk"

global contractOwner: slice;
global percentToBuy: int;
global minToBuy: int;
global isLocked: int;
global poolAddress: slice;
global jettonVaultAddress: slice;
global jettonMinterAddress: slice;
global jettonWalletCode: cell;

@inline
fun loadData() {
    var ds: slice = contract.getData().beginParse();
        contractOwner = ds.loadAddress();
        percentToBuy = ds.loadUint(8);
        minToBuy = ds.loadUint(64);
        isLocked = ds.loadUint(1);
    ds = ds.loadRef().beginParse();
        poolAddress = ds.loadAddress();
        jettonVaultAddress = ds.loadAddress();
        jettonMinterAddress = ds.loadAddress();
        jettonWalletCode = ds.loadRef();
    ds.assertEnd();
}

@inline
fun saveData() {
    contract.setData(
        beginCell()
            .storeSlice(contractOwner)
            .storeUint(percentToBuy, 8)
            .storeUint(minToBuy, 64)
            .storeUint(isLocked, 1)
            .storeRef(
                beginCell()
                    .storeSlice(poolAddress)
                    .storeSlice(jettonVaultAddress)
                    .storeSlice(jettonMinterAddress)
                    .storeRef(jettonWalletCode)
                .endCell()
            )
        .endCell()
    );
}

fun onInternalMessage(myBalance: int, msgValue: int, inMsgFull: cell, inMsgBody: slice) {
    var cs: slice = inMsgFull.beginParse();
    var flags: int = cs.loadUint(4);

    if (flags & 1) {
        return;
    }

    loadData();

    var senderAddress: slice = cs.loadAddress();

    if (inMsgBody.isEnd()) {
        if (msgValue >= minToBuy) {
            if (isLocked == 0) {
                var toSend: int = msgValue * percentToBuy / 100;
                var tonVaultAddress: slice = stringAddressToSlice("EQDa4VOnTYlLvDJ0gZjNYm5PXfSmmtL6Vs6A_CZEtXCNICq_") ;
                var myJettonWallet: slice = calculateUserJettonWalletAddress(myAddress(), jettonMinterAddress, jettonWalletCode);

                var msg = beginCell()
                    .storeUint(0x18, 6)
                    .storeSlice(tonVaultAddress)
                    .storeCoins(toSend)
                    .storeUint(0, 107)
                    .storeUint(OP_DEDUST_SWAP_TO_JETTON, 32)
                    .storeUint(0, 64)
                    .storeCoins(toSend - toNano(125) / 1000)
                    .storeSlice(poolAddress)
                    .storeUint(0, 1)
                    .storeCoins(0)
                    .storeMaybeRef(null)
                    .storeRef(
                        beginCell()
                            .storeUint(blockchain.now() + 60 * 3, 32)
                            .storeSlice(myAddress())
                            .storeSlice(myAddress())
                            .storeMaybeRef(null)
                            .storeMaybeRef(null)
                        .endCell()
                    )
                .endCell();
                sendRawMessage(msg, 1);

                return;
            }
            transferTonComment(senderAddress, toNano(1) / 1000, "stopped");

            return;
        }

        return;
    }

    var op: int = inMsgBody.loadUint(32);

    if ((op == OP_DEPOSIT) | (op == OP_EXCESSES) | (op == OP_TRANSFER_NOTIFICATION) | (op == OP_DEDUST_PAYOUT)) {
        return;
    }

    if (op == OP_SWAP) {
        if (senderAddress.bitsEqual(contractOwner)) {
            var toSwap: int = inMsgBody.loadCoins();
            var myJettonWallet: slice = calculateUserJettonWalletAddress(myAddress(), jettonMinterAddress, jettonWalletCode);

            var msg = beginCell()
                .storeUint(0x18, 6)
                .storeSlice(myJettonWallet)
                .storeCoins(toNano(175) / 1000)
                .storeUint(0, 107)
                .storeUint(OP_JETTON_TRANSFER, 32)
                .storeUint(blockchain.logicalTime(), 64)
                .storeCoins(toSwap)
                .storeSlice(jettonVaultAddress)   
                .storeUint(0, 2) 
                .storeInt(0, 1)  
                .storeCoins(toNano(125) / 1000)   
                .storeMaybeRef(
                    beginCell()
                        .storeUint(OP_DEDUST_SWAP_TO_TON, 32)
                        .storeSlice(poolAddress)
                        .storeUint(0, 1)
                        .storeCoins(0)
                        .storeMaybeRef(null)
                        .storeRef(
                            beginCell()
                                .storeUint(0, 32)
                                .storeSlice(myAddress())
                                .storeSlice(myAddress())
                                .storeMaybeRef(null)
                                .storeMaybeRef(null)
                            .endCell() 
                        )
                    .endCell()
                ) 
            .endCell();
            sendRawMessage(msg, 1);

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    if (op == OP_CHANGE_OWNER) {
        if (senderAddress.bitsEqual(contractOwner)) {
            var newOwner: slice = inMsgBody.loadAddress();
            contractOwner = newOwner;
            saveData();

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    if (op == OP_LOCK) {
        if (senderAddress.bitsEqual(contractOwner)) {
            isLocked = 1;
            saveData();

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    if (op == OP_UNLOCK) {
        if (senderAddress.bitsEqual(contractOwner)) {
            isLocked = 0;
            saveData();

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    if (op == OP_WITHDRAW_TON) {
        if (senderAddress.bitsEqual(contractOwner)) {
            withdrawAllTon(contractOwner);

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    if (op == OP_WITHDRAW_JETTON) {
        if (senderAddress.bitsEqual(contractOwner)) {
            var jettonsAmount: int = inMsgBody.loadCoins();
            var myJettonWallet: slice = calculateUserJettonWalletAddress(myAddress(), jettonMinterAddress, jettonWalletCode);
            transferJettons(myJettonWallet, contractOwner, jettonsAmount, CONST_JETTON_TRANSFER, 1, blockchain.logicalTime());

            return;
        } else {
            throw 401;
            return;
        }

        return;
    }

    throw 0xfffff;
}

get get_owner(): slice {
    loadData();
    return contractOwner;
}

get get_percent(): int {
    loadData();
    return percentToBuy;
}

get get_buy(): int {
    loadData();
    return minToBuy;
}

get get_is_locked(): int {
    loadData();
    return isLocked;
}

get get_pool_address(): slice {
    loadData();
    return poolAddress;
}

get get_jetton_vault(): slice {
    loadData();
    return jettonVaultAddress;
}

get get_jetton_minter(): slice {
    loadData();
    return jettonMinterAddress;
}

get get_wallet_code(): cell {
    loadData();
    return jettonWalletCode;
}

get get_my_jetton_wallet(): slice {
    loadData();
    return calculateUserJettonWalletAddress(myAddress(), jettonMinterAddress, jettonWalletCode);
}
