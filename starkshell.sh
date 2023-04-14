#!/bin/bash
export DEVNET=http://127.0.0.1:5050
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK=alpha-goerli
export BOOTSTRAPPER_SRC=./build/Bootstrapper.json
export FELTMAP_SRC=./build/FeltMap.json
export ERC721_SRC=./build/ERC721.json
export ERC1155_SRC=./build/ERC1155.json
export ERC20_SRC=./build/ERC20.json
export ERC5114_SRC=./build/ERC5114.json
export FLOBDB_SRC=./build/FlobDB.json
export STARKSHELL_SRC=./build/StarkShell.json
export DIAMOND_SRC=./build/Diamond.json
export DIAMOND_CUT_SRC=./build/DiamondCut.json
export METADATA_SRC=./build/UniversalMetadata.json
export SETSHELLFUN=$(python3.9 -c "from starkware.starknet.public.abi import get_selector_from_name; print(get_selector_from_name('setShellFun'))")
export MINT_CONTRACT=$(python3.9 -c "from starkware.starknet.public.abi import get_selector_from_name; print(get_selector_from_name('mintContract'))")


# Declare contract and filter output for class hash
declare_class () {
    declare_output=$(starknet declare --contract $1 \
        --gateway_url $DEVNET --feeder_gateway_url $DEVNET)
    echo $declare_output | grep "class hash" | awk '{print $NF}'
}


echo "Compile contracts"
protostar build


echo "Compile StarkShell functions"
cairo-compile src/starkshell/printSetShellFunCode.cairo --output build/printSetShellFunCode.json
cairo-compile src/starkshell/printMintContractCode.cairo --output build/printMintContractCode.json


echo "Create account"
ACCOUNT0=0x51cc82f8ab2d80899b97e30330fc9210da510facbe5b39edd0d49848e437530
cat >$HOME/.starknet_accounts/starknet_open_zeppelin_accounts.json <<EOL
{
    "alpha-goerli": {
        "__default__": {
            "private_key": "0x54304f405dce0f150d400de64a2412739eb48f655d499fe9cd46e1749f23e1a",
            "public_key": "0x6048bbaaa21f3a4a6500302c50dc0f2e90c9a6f894e7430e51fd05d0bc69b4f",
            "salt": "0x1f1f5f3cd6bc6ab4bcb5dfc2ac3c6fe4c5620bb03b44c388972ec394ba8bea5",
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
    --data '{"address": "0x51cc82f8ab2d80899b97e30330fc9210da510facbe5b39edd0d49848e437530", "amount": 1000000000000000000000}' \
    &> /dev/null

starknet deploy_account \
    --gateway_url $DEVNET \
    --feeder_gateway_url $DEVNET \
    &> /dev/null


echo "Declare contracts"
echo -ne " $(echo $((100 * 0/11)))% | Bootstrapper       \r"
export BOOTSTRAPPER_HASH=$(declare_class $BOOTSTRAPPER_SRC)

echo -ne " $(echo $((100 * 1/11)))% | BFR                \r"
export FELTMAP_HASH=$(declare_class $FELTMAP_SRC)

echo -ne " $(echo $((100 * 2/11)))% | FlobDB             \r"
export FLOBDB_HASH=$(declare_class $FLOBDB_SRC)

echo -ne " $(echo $((100 * 3/11)))% | StarkShell         \r"
export STARKSHELL_HASH=$(declare_class $STARKSHELL_SRC)

echo -ne " $(echo $((100 * 4/11)))% | Diamond            \r"
export DIAMOND_HASH=$(declare_class $DIAMOND_SRC)

echo -ne " $(echo $((100 * 5/11)))% | DiamondCut         \r"
export DIAMOND_CUT_HASH=$(declare_class $DIAMOND_CUT_SRC)

echo -ne " $(echo $((100 * 6/11)))% | ERC721             \r"
export ERC721_HASH=$(declare_class $ERC721_SRC)

echo -ne " $(echo $((100 * 7/11)))% | ERC1155            \r"
export ERC1155_HASH=$(declare_class $ERC1155_SRC)

echo -ne " $(echo $((100 * 8/11)))% | ERC20              \r"
export ERC20_HASH=$(declare_class $ERC20_SRC)

echo -ne " $(echo $((100 * 9/11)))% | ERC5114            \r"
export ERC5114_HASH=$(declare_class $ERC5114_SRC)

echo -ne " $(echo $((100 * 10/11)))% | UniversalMetadata \r"
export METADATA_HASH=$(declare_class $METADATA_SRC)

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
        $FELTMAP_HASH \
        $DIAMOND_HASH \
        $DIAMOND_CUT_HASH \
        $ERC721_HASH \
        $ERC1155_HASH \
        $ERC20_HASH \
        $ERC5114_HASH \
        $FLOBDB_HASH \
        $BOOTSTRAPPER_HASH \
        $STARKSHELL_HASH \
        $METADATA_HASH \
        $SETSHELLFUN \
        44 \
        $(cairo-run --program build/printSetShellFunCode.json --print_output --layout=small | tail -n +2 | xargs) \
        $MINT_CONTRACT \
        313 \
        $(cairo-run --program build/printMintContractCode.json --print_output --layout=small | tail -n +2 | xargs) --abi ./build/Bootstrapper_abi.json --gateway_url $DEVNET --feeder_gateway_url $DEVNET
