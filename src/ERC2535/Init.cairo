%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import split_felt, assert_not_zero
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import (
    deploy,
    library_call,
    get_caller_address,
    get_contract_address,
    get_block_number,
)
from starkware.cairo.common.uint256 import Uint256

from src.constants import FUNCTION_SELECTORS
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction
from src.ERC2535.library import Diamond
from src.BFR.IBFR import IBFR
from src.zklang.library import Function
from src.Factory.library import Factory

struct BFRCalldata {
    erc721ClassHash: felt,
    bfrClassHash: felt,
    flobDbClassHash: felt,
    zklangClassHash: felt,
    diamondCutClassHash: felt,
}

struct ERC721Calldata {
    receiver: felt,
    tokenId_len: felt,  // 1
    tokenId_low: felt,
    tokenId_high: felt,
}

struct FlobDbCalldata {
    receiver: felt,
    tokenId_len: felt,  // 1
    tokenId0: Uint256,
}

struct ZKLangCalldata {
    function: Function,
}

struct DiamondCutCalldata {
    null: felt,
}

struct DiamondCalldata {
    root: felt,
    facetKey: felt,
    initFacet: felt,
}

struct ClassHash {
    bfr: felt,
    diamond: felt,
    diamondCut: felt,
    erc721: felt,
    flobDb: felt,
    self: felt,
    zklang: felt,
}

@contract_interface
namespace IBootstrap {
    func init(
        _owner: felt,
        _tokenId: Uint256,
        _class: ClassHash,
        _setZKLfun_selector: felt,
        _setZKLfun_hash: felt,
        _setZKLfun_compiled_len: felt,
        _setZKLfun_compiled: felt*,
    ) -> () {
    }
}

@constructor
func constructor{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    _class: ClassHash,
    _setZKLfun_selector: felt,
    _setZKLfun_compiled_len: felt,
    _setZKLfun_compiled: felt*,
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (hash) = hash_chain{hash_ptr=pedersen_ptr}(_setZKLfun_compiled);
    let (block_number) = get_block_number();
    let salt = block_number * caller;

    let (high, low) = split_felt(self);
    let selfTokenId = Uint256(low, high);

    // Deploy a root diamond with self as only facet
    with_attr error_message("UNINITIALIZED DIAMOND CLASS") {
        assert_not_zero(_class.diamond);
    }

    with_attr error_message("FAILED DEPLOYMENT") {
        let (rootAddress) = deploy(
            class_hash=_class.diamond,
            contract_address_salt=salt,
            constructor_calldata_size=DiamondCalldata.SIZE,
            constructor_calldata=new (DiamondCalldata(0, 0, _class.self)),
            deploy_from_zero=FALSE,
        );
    }
    IBootstrap.init(
        rootAddress,
        caller,
        selfTokenId,
        _class,
        _setZKLfun_selector,
        hash,
        _setZKLfun_compiled_len,
        _setZKLfun_compiled,
    );

    return ();
}

// Pseudo-facet
@external
func init{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    _owner: felt,
    _tokenId: Uint256,
    _class: ClassHash,
    _setZKLfun_selector: felt,
    _setZKLfun_hash: felt,
    _setZKLfun_compiled_len: felt,
    _setZKLfun_compiled: felt*,
) -> () {
    alloc_locals;

    let (self) = get_contract_address();
    let (high, low) = split_felt(self);

    let facetCut_len = 5;
    tempvar facetCut: FacetCut* = cast(new (
        FacetCut(_class.bfr, FacetCutAction.Add),
        FacetCut(_class.erc721, FacetCutAction.Add),
        FacetCut(_class.zklang, FacetCutAction.Add),
        FacetCut(_class.diamondCut, FacetCutAction.Add),
        FacetCut(_class.flobDb, FacetCutAction.Add),
        ), FacetCut*);

    let tmp_len = (BFRCalldata.SIZE + 2) + (ERC721Calldata.SIZE + 1) + (ZKLangCalldata.SIZE + 2) + (DiamondCutCalldata.SIZE + 1);
    // let tmp_len = (BFRCalldata.SIZE + 2) + (ERC721Calldata.SIZE + 2) + (ZKLangCalldata.SIZE + 2) + (DiamondCutCalldata.SIZE + 2);
    tempvar tmp = cast(new (
        // BFRCalldata.SIZE + 1,
        // tmp_len + _setZKLfun_compiled_len + 1,
        BFRCalldata.SIZE + 1,
        BFRCalldata.SIZE,
        BFRCalldata(
            _class.bfr,
            _class.erc721,
            _class.flobDb,
            _class.zklang,
            _class.diamondCut,
            ),
        // ERC721Calldata.SIZE + 1,
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=_owner,
            tokenId_len=1,
            tokenId_low=low,
            tokenId_high=high,
            ),
        ZKLangCalldata.SIZE + 1,
        1,
        ZKLangCalldata(Function(_setZKLfun_selector, _setZKLfun_hash, 0)),  // TODO if 0 look for self
        // DiamondCutCalldata.SIZE,
        // DiamondCutCalldata(0),
        1, 0,
        ), felt*);

    let (local calldata: felt*) = alloc();
    memcpy(calldata, tmp, tmp_len);
    assert calldata[tmp_len] = _setZKLfun_compiled_len;
    // assert calldata[tmp_len + 1] = _setZKLfun_compiled_len;
    memcpy(calldata + tmp_len + 1, _setZKLfun_compiled, _setZKLfun_compiled_len);
    let calldata_len = tmp_len + (_setZKLfun_compiled_len + 1);
    // memcpy(calldata + tmp_len + 2, _setZKLfun_compiled, _setZKLfun_compiled_len);
    // let calldata_len = tmp_len + (_setZKLfun_compiled_len + 2);

    Diamond._diamondCut(facetCut_len, facetCut, calldata_len, calldata);

    // Activate configuration
    Diamond._set_root_(self);
    Diamond._set_facet_key_(facetCut_len ** 2 - 1);
    Diamond._set_init_root_(0);

    return ();
}

@view
func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    return (res=_el_len);  // TODO does this work? return simply NULL?
}

@view
@raw_output
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=2, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.Init.init;
    dw FUNCTION_SELECTORS.IBFR.calculateKey;
}

// is this redundant?
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}