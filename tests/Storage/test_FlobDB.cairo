%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
from src.Storage.IFlobDB import IFlobDB

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;


struct Setup {
    diamond_address: felt,
    storage_class_hash: felt,
}

func getSetup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Setup {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local storage_class_hash;
    %{ ids.storage_class_hash = context.storage_class_hash %}

    local setup: Setup = Setup(
        diamond_address,
        storage_class_hash,
    );
    return setup;
}


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local diamondCut_class_hash;
    local storage_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.storage_class_hash = declare("./src/Storage/FlobDB.cairo").class_hash
        ids.storage_class_hash = context.storage_class_hash;
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
    %}
    
    local TCF_address;
    %{  
        # Deploy BFR and TCF
        context.BFR_address = deploy_contract(
                "./src/main/BFR/BFR.cairo",
                [
                    ids.BrilliantBlocks, # Owner
                ],
        ).contract_address
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    context.BFR_address,
                    0, # DO_NOT_CARE name
                    0, # DO_NOT_CARE symbol
                    0, # DO_NOT_CARE tokenURI
                ],
        ).contract_address
        ids.TCF_address = context.TCF_address
    %}

    // BrilliantBlocks populates facet registry
    tempvar elements: felt* = new (diamondCut_class_hash, storage_class_hash);
    let elements_len = 2;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    tempvar facetCut: FacetCut* = cast(new (FacetCut(storage_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (0);
    let calldata_len = 1;

    // User adds storage facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@external
func test_store_populates_non_zero_flob{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let setup = getSetup();
    tempvar testdata: felt* = new (5,1,2,3,4,5);
    let (hash) = IFlobDB.store(setup.diamond_address, 6, testdata);

    let (actual_data_len, actual_data) = IFlobDB.load(setup.diamond_address, hash);
    assert_eq(actual_data_len, 5);
    assert_eq(actual_data[0], 1);
    assert_eq(actual_data[1], 2);
    assert_eq(actual_data[2], 3);
    assert_eq(actual_data[3], 4);
    assert_eq(actual_data[4], 5);
    return ();
}

@external
func test_store_populates_zero_ish_flob{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let setup = getSetup();
    tempvar testdata: felt* = new (6,0,0,0,0,0,0);
    let (hash) = IFlobDB.store(setup.diamond_address, 7, testdata);

    let (actual_data_len, actual_data) = IFlobDB.load(setup.diamond_address, hash);
    assert_eq(actual_data_len, 6);
    assert_eq(actual_data[0], 0);
    assert_eq(actual_data[1], 0);
    assert_eq(actual_data[2], 0);
    assert_eq(actual_data[3], 0);
    assert_eq(actual_data[4], 0);
    assert_eq(actual_data[5], 0);
    return ();
}

@external
func test_store_maintains_consistency_over_multiple_flobs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let setup = getSetup();

    tempvar testdata: felt* = new (6,0,0,0,0,0,0);
    let (hash) = IFlobDB.store(setup.diamond_address, 7, testdata);

    tempvar testdata: felt* = new (5,1,2,3,4,5);
    let (hash) = IFlobDB.store(setup.diamond_address, 6, testdata);

    tempvar testdata: felt* = new (7,1,2,3,4,5, 1, -1000);
    let (hash) = IFlobDB.store(setup.diamond_address, 8, testdata);

    return ();
}

@external
func test_store_does_not_write_to_tmp_var{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();

    tempvar testdata: felt* = new (5,1,2,3,4,5);
    IFlobDB.store(setup.diamond_address, 6, testdata);
    %{
        tmp_var = load(context.diamond_address, "storage_internal_temp_var", "felt")[0]
        assert tmp_var == 0
    %}
    return();
}
