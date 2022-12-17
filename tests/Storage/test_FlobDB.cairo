%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction

from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.interfaces.ITCF import ITCF
from src.zkode.facets.storage.flobdb.IFlobDB import IFlobDB

from tests.setup import (
    ClassHash,
    get_class_hashes,
    compute_selectors,
    declare_contracts,
    deploy_bootstrapper,
    deploy_root,
)

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;

@external
func __setup__{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    compute_selectors();
    declare_contracts();
    deploy_bootstrapper();
    deploy_root();

    local root;
    %{ ids.root = context.root %}

    let ch: ClassHash = get_class_hashes();  // User mints a test diamond

    tempvar facetCut = new FacetCut(ch.flobDb, FacetCutAction.Add);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (2, 0, 0);
    let calldata_len = 3;
    %{ stop_prank = start_prank(ids.User, context.root) %}
    let (diamond_address) = ITCF.mintContract(root, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_store_populates_non_zero_flob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (5, 1, 2, 3, 4, 5);
    let (hash) = IFlobDB.store(diamond_address, 6, testdata);

    let (actual_data_len, actual_data) = IFlobDB.load(diamond_address, hash);
    assert_eq(actual_data_len, 5);
    assert_eq(actual_data[0], 1);
    assert_eq(actual_data[1], 2);
    assert_eq(actual_data[2], 3);
    assert_eq(actual_data[3], 4);
    assert_eq(actual_data[4], 5);
    return ();
}

@external
func test_store_populates_zero_ish_flob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (6, 1, 0, 0, 0, 0, 0);
    let (hash) = IFlobDB.store(diamond_address, 7, testdata);

    let (actual_data_len, actual_data) = IFlobDB.load(diamond_address, hash);
    assert_eq(actual_data_len, 6);
    assert_eq(actual_data[0], 1);
    assert_eq(actual_data[1], 0);
    assert_eq(actual_data[2], 0);
    assert_eq(actual_data[3], 0);
    assert_eq(actual_data[4], 0);
    assert_eq(actual_data[5], 0);
    return ();
}

@external
func test_store_maintains_consistency_over_multiple_flobs{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (6, 0, 0, 0, 0, 0, 0);
    let (hash) = IFlobDB.store(diamond_address, 7, testdata);

    tempvar testdata: felt* = new (5, 1, 2, 3, 4, 5);
    let (hash) = IFlobDB.store(diamond_address, 6, testdata);

    tempvar testdata: felt* = new (7, 1, 2, 3, 4, 5, 1, -1000);
    let (hash) = IFlobDB.store(diamond_address, 8, testdata);

    return ();
}

@external
func test_store_does_not_write_to_tmp_var{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (5, 1, 2, 3, 4, 5);
    IFlobDB.store(diamond_address, 6, testdata);
    %{
        tmp_var = load(context.diamond_address, "storage_internal_temp_var", "felt")[0]
        assert tmp_var == 0
    %}
    return ();
}

@external
func test_loadCell_of_zero_returns_first_element{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (6, 2, 0, 0, 0, 0, 0);
    let (hash) = IFlobDB.store(diamond_address, 7, testdata);

    let (actual_data) = IFlobDB.loadCell(diamond_address, hash, 0);
    assert_eq(actual_data, 2);
    return ();
}

@external
func test_loadCell_of_last_index_returns_last_element{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (6, 2, 0, 0, 0, 0, 3);
    let (hash) = IFlobDB.store(diamond_address, 7, testdata);

    let (actual_data) = IFlobDB.loadCell(diamond_address, hash, 5);
    assert_eq(actual_data, 3);

    let (actual_data) = IFlobDB.loadCell(diamond_address, hash, 0);
    assert_eq(actual_data, 2);
    return ();
}

@external
func test_loadRange__returns_subset{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar testdata: felt* = new (6, 2, 0, 0, 0, 0, 3);
    let (hash) = IFlobDB.store(diamond_address, 7, testdata);

    let (actual_data_len, actual_data) = IFlobDB.loadRange(diamond_address, hash, 3, 5);
    assert_eq(actual_data_len, 3);
    assert_eq(actual_data[0], 0);
    assert_eq(actual_data[1], 0);
    assert_eq(actual_data[2], 3);
    return ();
}
