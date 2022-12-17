%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import (
    deploy,
    get_block_number,
    get_caller_address,
    get_contract_address,
)

from src.bootstrap.IBootstrapper import IBootstrapper
from src.bootstrap.structs import DiamondCalldata
from src.zkode.constants import FUNCTION_SELECTORS
from src.zkode.diamond.structs import FacetCut
from src.zkode.diamond.library import Diamond

@event
func DeployRoot(address: felt) {
}

@constructor
func constructor(_dont_care: felt) {
    return ();
}

@external
func deployRoot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _salt: felt,
    _diamond_class_hash: felt,
    _this_class_hash: felt,
    _feltmap_class_hash: felt,
    _facetCut_len: felt,
    _facetCut: FacetCut*,
    _calldata_len: felt,
    _calldata: felt*,
) -> (address: felt) {
    alloc_locals;

    let (address) = deploy_root(_salt, _diamond_class_hash, _this_class_hash, _feltmap_class_hash);

    IBootstrapper.initRoot(address, _facetCut_len, _facetCut, _calldata_len, _calldata);

    DeployRoot.emit(address);

    return (address=address);
}

// Called as a facet function from root
@external
func initRoot{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(_facetCut_len: felt, _facetCut: FacetCut*, _calldata_len: felt, _calldata: felt*) -> () {
    alloc_locals;

    Diamond._diamondCut(_facetCut_len, _facetCut, _calldata_len, _calldata);

    // Deployed diamond becomes its own root
    let (self) = get_contract_address();
    Diamond._set_root_(self);

    // Include all facets
    let (facet_key) = pow(2, _facetCut_len);
    local facet_key = facet_key - 1;
    Diamond._set_facet_key_(facet_key);

    // Undo write to storage
    Diamond._set_init_root_(0);

    return ();
}

@view
func precomputeRootAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _salt: felt,
    _diamond_class_hash: felt,
    _this_class_hash: felt,
    _feltmap_class_hash: felt,
    _facetCut_len: felt,
    _facetCut: FacetCut*,
    _calldata_len: felt,
    _calldata: felt*,
) -> (address: felt) {
    alloc_locals;

    let (address) = deploy_root(_salt, _diamond_class_hash, _this_class_hash, _feltmap_class_hash);

    return (address=address);
}

func deploy_root{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _salt: felt, _diamond_class_hash: felt, _this_class_hash: felt, _feltmap_class_hash: felt
) -> (address: felt) {
    alloc_locals;

    // Root diamonds are created with this contract as their only facet
    let (address) = deploy(
        class_hash=_diamond_class_hash,
        contract_address_salt=_salt,
        constructor_calldata_size=DiamondCalldata.SIZE,
        constructor_calldata=new (DiamondCalldata(0, 0, _this_class_hash, _feltmap_class_hash)),
        deploy_from_zero=FALSE,
    );

    return (address=address);
}

// @dev Required interface subset of FeltMap
@view
func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    return (res=0);
}

@view
@raw_output
func __pub_func__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);

    return (retdata_size=2, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.IBootstrapper.initRoot;
    dw FUNCTION_SELECTORS.IFeltMap.calculateKey;
}
