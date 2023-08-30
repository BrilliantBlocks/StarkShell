%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.components.diamond.structs import FacetCut, FacetCutAction

from src.components.diamond.IDiamond import IDiamond
from src.components.facets.upgradability.IDiamondCut import IDiamondCut
from src.components.interfaces.ITCF import ITCF
from src.components.facets.storage.flobdb.IFlobDB import IFlobDB

from tests.setup import (
    ClassHash,
    getClassHashes,
    computeSelectors,
    declareContracts,
    deployRootDiamondFactory,
    deployRootDiamond,
)

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;

@external
func __setup__{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    computeSelectors();
    declareContracts();
    deployRootDiamondFactory();
    deployRootDiamond();

    local rootDiamond;
    %{ ids.rootDiamond = context.rootDiamond %}

    let ch: ClassHash = getClassHashes();  // User mints a test diamond

    tempvar facetCut = new FacetCut(ch.flobDb, FacetCutAction.Add);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (2, 0, 0);
    let calldata_len = 3;
    %{ stop_prank = start_prank(ids.User, context.rootDiamond) %}
    let (diamond_address) = ITCF.mintContract(
        rootDiamond, facetCut_len, facetCut, calldata_len, calldata
    );
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
