%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import split_felt, assert_not_equal
from starkware.cairo.common.uint256 import Uint256

from src.constants import NULL
from src.ERC2535.IDiamondCut import FacetCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User1 = 456;
const User2 = 789;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local diamondCut_class_hash;
    %{
        from tests.util import str_to_felt, str_to_felt_array
        context.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        ids.BFR_address = context.BFR_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        ids.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.name = str_to_felt("zkode_v0.1")
        context.symbol = str_to_felt("zkc")
        context.tokenURI = str_to_felt_array("https://zkode.brilliantblocks.io")
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    context.BFR_address,
                    context.name,
                    context.symbol,
                    len(context.tokenURI),
                    *context.tokenURI,
                ],
            ).contract_address
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=ids.BFR_address
        )
    %}
    IBFR.registerElement(BFR_address, diamondCut_class_hash);
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_name{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    local expected_name;
    %{ ids.TCF_address = context.TCF_address %}
    %{ ids.expected_name = context.name %}

    let (actual_name) = ITCF.name(TCF_address);
    assert_eq(actual_name, expected_name);
    
    return ();
}

@external
func test_symbol{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    local expected_symbol;
    %{ ids.TCF_address = context.TCF_address %}
    %{ ids.expected_symbol = context.symbol %}

    let (actual_symbol) = ITCF.symbol(TCF_address);
    assert_eq(actual_symbol, expected_symbol);
    
    return ();
}

@external
func test_tokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    let (local NULLptr: felt*) = alloc();
    let (local FCNULLptr: FacetCut*) = alloc();
    local TCF_address;
    local expected_tokenURI0;
    local expected_tokenURI1;
    %{
        ids.TCF_address = context.TCF_address
        ids.expected_tokenURI0 = context.tokenURI[0]
        ids.expected_tokenURI1 = context.tokenURI[1]
        stop_prank_callable = start_prank(ids.User1, target_contract_address=ids.TCF_address)
    %}
    // Mint a diamond
    let (diamond_address1) = ITCF.mintContract(TCF_address, NULL, FCNULLptr, NULL, NULLptr);
    %{ stop_prank_callable() %}
    let (high, low) = split_felt(diamond_address1);
    let tokenId = Uint256(low, high);

    let (actual_tokenURI_len, actual_tokenURI) = ITCF.tokenURI(TCF_address, tokenId);
    assert_eq(actual_tokenURI_len, 2);
    assert_eq(actual_tokenURI[0], expected_tokenURI0);
    assert_eq(actual_tokenURI[1], expected_tokenURI1);

    %{ stop_prank_callable = start_prank(ids.User2, target_contract_address=ids.TCF_address) %}
    // Mint another diamond
    let (diamond_address2) = ITCF.mintContract(TCF_address, NULL, FCNULLptr, NULL, NULLptr);
    %{ stop_prank_callable() %}
    let (high, low) = split_felt(diamond_address2);
    let tokenId = Uint256(low, high);

    // Second diamond has the same tokenURI
    let (actual_tokenURI_len, actual_tokenURI) = ITCF.tokenURI(TCF_address, tokenId);
    assert_eq(actual_tokenURI_len, 2);
    assert_eq(actual_tokenURI[0], expected_tokenURI0);
    assert_eq(actual_tokenURI[1], expected_tokenURI1);

    return ();
}

@external
func test_tokenURI_reverts_unknown_tokenId{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    %{
        ids.TCF_address = context.TCF_address
        expect_revert(error_message="UNKNOWN TOKEN ID")
    %}
    let (actual_tokenURI_len, actual_tokenURI) = ITCF.tokenURI(TCF_address, Uint256(0, 0));

    return ();
}
