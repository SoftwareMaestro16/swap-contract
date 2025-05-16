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

                var myJettonWallet: slice = calculateUserJettonWalletAddress(myAddress(), jettonMinterAddress, jettonWalletCode);

                swapToJettonDeDust(toSend, poolAddress);

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

            swapToTonDeDust(myJettonWallet, jettonVaultAddress, toSwap, poolAddress);

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
