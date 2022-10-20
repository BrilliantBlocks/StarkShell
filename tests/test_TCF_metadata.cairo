%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.ERC2535.IDiamondCut import IDiamondCut
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    %{
        from tests.util import str_to_felt, str_to_felt_array
        context.name = str_to_felt("zkode_v0.1")
        context.symbol = str_to_felt("zkc")
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    0, # DO_NOT_CARE Diamond_class_hash
                    0, # DO_NOT_CARE BFR_address
                    context.name,
                    context.symbol,
                    # *str_to_felt_array("https://zkode.brilliantblocks.io"),
                    0,
                ],
            ).contract_address
    %}
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
