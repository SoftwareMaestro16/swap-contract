/*
    Updated library for Tolk.
 
    This file is part of Tolk Standard Library.

    A collection of helper functions for simplified development in the Tolk language.
    Contains commonly used utilities to reduce boilerplate and improve code readability.

    by SoftwareMaestro:
    https://github.com/SoftwareMaestro16
    https://t.me/SoftwareMaestro
*/

@pure
fun curLt(): int
    asm "LTIME";
@pure
fun now(): int
    asm "NOW";
@pure
fun myAddress(): slice
    asm "MYADDR";
@pure
fun block_lt(): int
    asm "BLOCKLT";

// upd:
// contract.getAddress();
// contract.setData(c);
// blockchain.logicalTime();

@inline
fun packJettonWalletData(balance: int, ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): cell {
   return  beginCell()
            .storeCoins(balance)
            .storeSlice(ownerAddress)
            .storeSlice(jettonMasterAddress)
            .storeRef(jettonWalletCode)
           .endCell();
}

@inline
fun calculateJettonWalletStateInit(ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): cell {
  return beginCell()
          .storeUint(0, 2)
          .storeDict(jettonWalletCode)
          .storeDict(packJettonWalletData(0, ownerAddress, jettonMasterAddress, jettonWalletCode))
          .storeUint(0, 1)
         .endCell();
}

@inline
fun calculateJettonWalletAddress(stateInit: cell): slice {
  return beginCell().storeUint(4, 3)
                     .storeInt(0, 8)
                     .storeUint(stateInit.hash(), 256)
                     .endCell()
                     .beginParse();
}

@inline
fun calculateUserJettonWalletAddress(ownerAddress: slice, jettonMasterAddress: slice, jettonWalletCode: cell): slice {
  return calculateJettonWalletAddress(calculateJettonWalletStateInit(ownerAddress, jettonMasterAddress, jettonWalletCode));
}

/*

    The following functions are provided as templates. In case any compilation errors occur, 
    these templates can be uncommented and used as a starting point for loading data, saving data, 
    and handling internal messages in the contract.

    fun loadData() {
        var ds = contract.getData().beginParse();

        ds.assertEnd();
        return ds;
    }

    fun saveData() {
        contract.setData(
            beginCell()

            .endCell()
        );
    }

    fun onInternalMessage(myBalance: int, msgValue: int, msgFull: cell, msgBody: slice) {
        if (msgBody.isEnd()) { // ignore all empty messages
            return;
        }

        ...

    ---

    struct StoredInfo {
        counterValue: int;
        ownerAddress: slice;
        updatedTime: uint64;
        lastCost: coins?;
    }

    fun loadData(): StoredInfo {
        var cs = getContractData().beginParse();
        return {
            counterValue: cs.loadInt(32),
            ownerAddress: cs.loadAddress(),
            updatedTime: cs.loadUint(64),
            lastCost: cs.loadCoins(),
        }
    }

    get lastUpdateTime() {
        return loadData().updatedTime;
    }

*/

/* CONSTS */

const CONST_MIN_RESERVE = 15000000;   // 0.015 TON 
const CONST_JETTON_TRANSFER = 55000000;   // 0.055 TON 
const CONST_BURN_JETTONS = 50000000;   // 0.05  TON 
const CONST_MIN_EXCESS = 10000000;   // 0.01  TON 
const CONST_DEPLOY = 50000000;   // 0.05  TON 
const CONST_MIN_TON_FOR_STORAGE = 50000000;   // 0.05  TON 

/* OP-CODES */

const OP_EXCESSES = 0xd53276db;
const OP_JETTON_TRANSFER = 0x0f8a7ea5;
const OP_TRANSFER_NOTIFICATION = 0x7362d09c;
const OP_PROVIDE_WALLET_ADDRESS = 0x2c76b973;
const OP_TAKE_WALLET_ADDRESS = 0xd1735400;
const OP_BURN_JETTON = 0x595f07bc;
const OP_SEND_ANY_MESSAGE = 0xa47d989c;
const OP_SET_CODE = 0xe2d2d211;
const OP_WITHDRAW_TON = 0x37726bdb;
const OP_WITHDRAW_JETTON = 0x11c09682;
const OP_DEACTIVATE_WALLET = 0x4b14c485;
const OP_NFT_TRANSFER = 0x5fcc3d14;
const OP_RECEIVED_NFT = 0x05138d91;
const OP_LOCK = 0x878f9b0e;
const OP_UNLOCK = 0x6ae4b0ef;
const OP_INCREMENT = 0x5588464e;
const OP_DECREMENT = 0xf9adbd4f;

/* OTHER */

const BURN_ADDRESS = stringAddressToSlice("EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c");
const WORKCHAIN = 0;
const ONE_TON = 1000000000;
const FIVE_CENT_TON = 50000000; // 0.05 

/* FUNCTIONS */

@inline
fun toNano(amount: int): int {
    if (amount < 0) {
        throw 922; 
    }
    return amount * 1000000000;
}

@inline
fun fromNano(amount: int): int {
    if (amount < 0) {
        throw 922;
    }
    return amount / 1000000000;
}

@inline
fun getContractAddress(workchain: int, stateInit: cell): slice {
    return beginCell()
        .storeUint(4, 3)
        .storeInt(workchain, 8)
        .storeUint(stateInit.hash(), 256)
    .endCell().beginParse();
}

@inline
fun pow(n: int, e: int): int {
  if (e == 0) {
    return 1;
  }

  if (e == 1) {
    return n;
  }

  var p: int = pow(n, (e / 2));
  p = p * p;
    
  if ((e % 2) == 1) {
    p = p * n;
  }
    
  return p;
}

@inline
fun sqrt(x: int): int {
  if (x == 0) { return x; }

  var r: int = 181;
  var xx: int = x;
  if (xx >= 0x100000000000000000000000000000000) {
    xx >>= 128;
    r <<= 64;
  }
  if (xx >= 0x10000000000000000) {
    xx >>= 64;
    r <<= 32;
  }
  if (xx >= 0x100000000) {
    xx >>= 32;
    r <<= 16;
  }
  if (xx >= 0x10000) {
    xx >>= 16;
    r <<= 8;
  }

  r = (r * (xx + 65536)) >> 18;

  repeat(7) {
    r = (r + x / r) >> 1;
  }

  var r1: int = x / r;

  return (r < r1 ? r : r1);
}

@inline
fun avg(x: int, y: int): int {
  return (x + y) / 2;
}

@inline
fun exp(x: int): int {
  return (x >= 0 ? 1 << x : 1 >> (x * -1));
}

@pure
fun log2(x: int): int
    asm "UBITSIZE DEC";

@pure
fun mod(x: int, y: int): int
    asm "MOD";

@inline
fun randRange(a: int, b: int): int {
    random.initializeBy(curLt() + now());
    return random.range(b - a) + a;
}

/* MESSAGES */

@inline_ref
fun sendWithStateInit(amount: int, to: slice, stateInit: cell, body: cell, mode: int) {
    var msg: cell = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(to)
        .storeCoins(amount)
        .storeUint(7, 108)
        .storeRef(stateInit)
        .storeRef(body)
    .endCell();
    sendRawMessage(msg, mode);
}

@inline
fun transferTonComment(senderAddress: slice, amount: int, comment: slice) {
    var msg = beginCell()
        .storeUint(0x10, 6)
        .storeSlice(senderAddress) 
        .storeCoins(amount)
        .storeUint(0, 107 + 32)
        .storeSlice(comment)
    .endCell();
    sendRawMessage(msg, 1);
}

@inline
fun transferTon(senderAddress: slice, amount: int) {
    var msg = beginCell()
        .storeUint(0x10, 6)
        .storeSlice(senderAddress) 
        .storeCoins(amount)
        .storeUint(0, 107)
    .endCell();
    sendRawMessage(msg, 1);
}

@inline
fun sendBounce(senderAddress: slice, msgValue: int) {
    var msg = beginCell()
        .storeUint(0x10, 6)
        .storeSlice(senderAddress) 
        .storeCoins(msgValue)
        .storeUint(0, 107)
    .endCell();
    sendRawMessage(msg, 64);
}

@inline
fun withdrawAllTon(senderAddress: slice) {
    var msg = beginCell()
        .storeUint(0x10, 6)
        .storeSlice(senderAddress) 
        .storeCoins(0)
        .storeUint(0, 107)
    .endCell();
    sendRawMessage(msg, 128);
}

@inline
fun transferJettons(toJettonWallet: slice, toAddress: slice, jettonsAmount: int, tonsAmont: int, sendMode: int, queryId: int) {
    var message: builder = 
        beginCell()
            .storeUint(0x18, 6)
            .storeSlice(toJettonWallet)
            .storeCoins(tonsAmont)
            .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .storeUint(OP_JETTON_TRANSFER, 32)
            .storeUint(queryId, 64)
            .storeCoins(jettonsAmount)
            .storeSlice(toAddress)    // to_owner_address
            .storeUint(0, 2)  // response_address (empty)
            .storeInt(0, 1)  // custom_payload (empty)
            .storeCoins(0)   // forward amount to new_owner_address (null)
            .storeInt(0, 1); // forward_payload (empty)
    
    sendRawMessage(message.endCell(), sendMode);
}

@inline
fun transferJettonsComment(toJettonWallet: slice, toAddress: slice, jettonsAmount: int, tonsAmont: int, sendMode: int, queryId: int, comment: slice) {
    var forwardPayload: cell = beginCell()
        .storeUint(0, 32)           // Indicates the presence of a comment
        .storeSlice(comment)        // Replace with your desired comment
    .endCell();

    var body: cell = beginCell()
        .storeUint(OP_JETTON_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeCoins(jettonsAmount)
        .storeSlice(toAddress)
        .storeSlice(toAddress)
        .storeInt(0, 2)  // custom_payload (empty)
        .storeCoins(22000000)       // forward amount to new_owner_address (null) 
        .storeInt(0, 1)
        .storeRef(forwardPayload)  // forward_payload (empty)
    .endCell();

    var message: builder = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(toJettonWallet)
        .storeCoins(tonsAmont)
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)  
        .storeRef(body);
    
    sendRawMessage(message.endCell(), sendMode);
}

@inline
fun transferNft(nftAddress: slice, queryId: int, senderAddress: slice) {
    var body: cell = beginCell()
        .storeUint(OP_NFT_TRANSFER, 32)      // Operation code for NFT transfer
        .storeUint(queryId, 64)              // Unique query identifier
        .storeSlice(senderAddress)           // New owner address
        .storeSlice(senderAddress)           // Response address
        .storeInt(0, 2)                       // Empty custom_payload (Maybe ^Cell)
        .storeCoins(22000000)                 // Forward amount to new owner
        .storeInt(0, 1)                       // No forward_payload (Either Cell ^Cell)
    .endCell();

    var nftMsg: builder = beginCell()
        .storeUint(0x18, 6)                   // Message header
        .storeSlice(nftAddress)              // Destination NFT address
        .storeCoins(50000000)                 // Amount of TON to send
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1) // Default message headers
        .storeRef(body);                      // Reference to the body

    sendRawMessage(nftMsg.endCell(), 1);
}

@inline
fun burnNft(nftAddress: slice, queryId: int) {
    var forwardPayload: cell = beginCell().endCell();

    var body: cell = beginCell()
        .storeUint(OP_NFT_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeSlice(BURN_ADDRESS) // new_owner_address
        .storeSlice(BURN_ADDRESS) // response_address
        .storeInt(0, 2)           // empty custom_payload
        .storeCoins(22000000)     // forward amount to new_owner_address
        .storeInt(0, 1)
        .storeRef(forwardPayload)
    .endCell();

    var nftMsg: builder = beginCell()
        .storeUint(0x18, 6)                   // Message header
        .storeSlice(nftAddress)              // Destination NFT address
        .storeCoins(50000000)                 // Amount of TON to send
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1) // Default message headers
        .storeRef(body);                      // Reference to the body

    sendRawMessage(nftMsg.endCell(), 1);
}

@inline
fun transferNftComment(nftAddress: slice, queryId: int, senderAddress: slice, comment: slice) {
    var forwardPayload: cell = beginCell()
            .storeUint(0, 32)           // Indicates the presence of a comment
            .storeSlice(comment)  // Replace with your desired comment
        .endCell();

    var body: cell = beginCell()
        .storeUint(OP_NFT_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeSlice(senderAddress) // new_owner_address
        .storeSlice(senderAddress) // response_address
        .storeInt(0, 2) // empty custom_payload
        .storeCoins(22000000) // forward amount to new_owner_address
        .storeInt(0, 1)
        .storeRef(forwardPayload)
    .endCell();

    var nftMsg: builder = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(nftAddress)
        .storeCoins(50000000)
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1) // default message headers (see sending messages page)
        .storeRef(body);

    sendRawMessage(nftMsg.endCell(), 1);
}

@inline
fun burnNftComment(nftAddress: slice, queryId: int, comment: slice) {
    var forwardPayload: cell = beginCell()
            .storeUint(0, 32)              // Indicates the presence of a comment
            .storeSlice(comment)  // Replace with your desired comment
        .endCell();

    var body: cell = beginCell()
        .storeUint(OP_NFT_TRANSFER, 32)
        .storeUint(queryId, 64)
        .storeSlice(BURN_ADDRESS) // new_owner_address
        .storeSlice(BURN_ADDRESS) // response_address
        .storeInt(0, 2)           // empty custom_payload
        .storeCoins(22000000)     // forward amount to new_owner_address
        .storeInt(0, 1)
        .storeRef(forwardPayload)
    .endCell();

    var nftMsg: builder = beginCell()
        .storeUint(0x18, 6)
        .storeSlice(nftAddress)
        .storeCoins(50000000)
        .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1) // default message headers (see sending messages page)
        .storeRef(body);

    sendRawMessage(nftMsg.endCell(), 1);
}

@inline
fun addComment(comment: slice): cell {
    return beginCell()
        .storeUint(0, 32)
        .storeSlice(comment)
    .endCell();
}
