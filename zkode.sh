#!/bin/bash
export DEVNET=http://127.0.0.1:5050
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK=alpha-goerli
export BOOTSTRAPPER_SRC=./build/Bootstrapper.json
export BFR_SRC=./build/BFR.json
export ERC721_SRC=./build/ERC721.json
export ERC1155_SRC=./build/ERC1155.json
export ERC20_SRC=./build/ERC20.json
export ERC5114_SRC=./build/ERC5114.json
export FLOB_SRC=./build/FlobDB.json
export ZKLANG_SRC=./build/ZKLANG.json
export DIAMOND_SRC=./build/Diamond.json
export DIAMOND_CUT_SRC=./build/DiamondCut.json
export METADATA_SRC=./build/UniversalMetadata.json
export SETZKLANGFUN=$(python3.9 -c "from starkware.starknet.public.abi import get_selector_from_name; print(get_selector_from_name('setZKLangFun'))")
export MINT_CONTRACT=$(python3.9 -c "from starkware.starknet.public.abi import get_selector_from_name; print(get_selector_from_name('mintContract'))")


# Declare contract and filter output for class hash
declare_class () {
    declare_output=$(starknet declare --contract $1 \
        --gateway_url $DEVNET --feeder_gateway_url $DEVNET)
    echo $declare_output | grep "class hash" | awk '{print $NF}'
}


echo "Compile contracts"
protostar build


echo "Compile ZKLang functions"
cairo-compile tests/zklang/fun/printZKLangCode.cairo --output build/printZKLangCode.json
cairo-compile tests/zklang/fun/printMintContractCode.cairo --output build/printMintContractCode.json


echo "Create account"
ACCOUNT0=0x148d26c1a88c45fa685db24983079a29dd942c20d9436394ff0741c4c7f0b64
cat >$HOME/.starknet_accounts/starknet_open_zeppelin_accounts.json <<EOL
{
    "alpha-goerli": {
        "__default__": {
            "private_key": "0x3b9bd4c5023334de575b184ab8659171d480559b24cbf66d04ab349c8e0f793",
            "public_key": "0x50a0f7dc68ad400d24880bbac5dfaabe963e2ec5f2101aaab8e06549044538f",
            "salt": "0x7630acc3036a5b0753864237065a2be8a48dc1bef6c4de3698be6a1ccfa4404",
            "address": "${ACCOUNT0}",
            "deployed": false
        }
    }
}
EOL

# NOTICE Account address is hardcoded
echo "Fund account"

curl $DEVNET/mint \
    -X POST -H 'Content-Type:application/json' \
    --data '{"address": "0x148d26c1a88c45fa685db24983079a29dd942c20d9436394ff0741c4c7f0b64", "amount": 1000000000000000000000}' \
    &> /dev/null

starknet deploy_account \
    --gateway_url $DEVNET \
    --feeder_gateway_url $DEVNET \
    &> /dev/null


echo "Declare contracts"
echo -ne " $(echo $((100 * 0/11)))% | Bootstrapper       \r"
BOOTSTRAPPER_HASH=$(declare_class $BOOTSTRAPPER_SRC)

echo -ne " $(echo $((100 * 1/11)))% | BFR                \r"
BFR_HASH=$(declare_class $BFR_SRC)

echo -ne " $(echo $((100 * 2/11)))% | FlobDB             \r"
FLOB_HASH=$(declare_class $FLOB_SRC)

echo -ne " $(echo $((100 * 3/11)))% | ZKLang             \r"
ZKLANG_HASH=$(declare_class $ZKLANG_SRC)

echo -ne " $(echo $((100 * 4/11)))% | Diamond            \r"
DIAMOND_HASH=$(declare_class $DIAMOND_SRC)

echo -ne " $(echo $((100 * 5/11)))% | DiamondCut         \r"
DIAMOND_CUT_HASH=$(declare_class $DIAMOND_CUT_SRC)

echo -ne " $(echo $((100 * 6/11)))% | ERC721             \r"
ERC721_HASH=$(declare_class $ERC721_SRC)

echo -ne " $(echo $((100 * 7/11)))% | ERC1155            \r"
ERC1155_HASH=$(declare_class $ERC1155_SRC)

echo -ne " $(echo $((100 * 8/11)))% | ERC20              \r"
ERC20_HASH=$(declare_class $ERC20_SRC)

echo -ne " $(echo $((100 * 9/11)))% | ERC5114            \r"
ERC5114_HASH=$(declare_class $ERC5114_SRC)

echo -ne " $(echo $((100 * 10/11)))% | UniversalMetadata \r"
METADATA_HASH=$(declare_class $METADATA_SRC)

echo -ne " ($(echo $((100 * 11/11)))%)                   \r"
echo -ne "\n"

echo "Deploy Bootstrapper"

BOOTSTRAPPER_ADDR=$(starknet deploy --class_hash $BOOTSTRAPPER_HASH --gateway_url $DEVNET --feeder_gateway_url $DEVNET --inputs 0 | grep "address" | awk '{print $NF}')


echo "Deploy root diamond from Bootstrapper"

# NOTICE zklang fun len are hardcoded
starknet invoke \
    --address $BOOTSTRAPPER_ADDR \
    --function deployRootDiamond \
    --inputs \
        $BFR_HASH \
        $DIAMOND_HASH \
        $DIAMOND_CUT_HASH \
        $ERC721_HASH \
        $ERC1155_HASH \
        $ERC20_HASH \
        $ERC5114_HASH \
        $FLOB_HASH \
        $BOOTSTRAPPER_HASH \
        $ZKLANG_HASH \
        $METADATA_HASH \
        $SETZKLANGFUN \
        44 \
        $(cairo-run --program build/printZKLangCode.json --print_output --layout=small | tail -n +2 | xargs) \
        $MINT_CONTRACT \
        299 \
        $(cairo-run --program build/printMintContractCode.json --print_output --layout=small | tail -n +2 | xargs) --abi ./build/Bootstrapper_abi.json --gateway_url $DEVNET --feeder_gateway_url $DEVNET
