%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import split_felt, assert_not_zero
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import (
    deploy,
    library_call,
    get_caller_address,
    get_contract_address,
    get_block_number,
)
from starkware.cairo.common.uint256 import Uint256

from src.zkode.constants import FUNCTION_SELECTORS
from src.zkode.ERC2535.structs import FacetCut, FacetCutAction
from src.zkode.ERC2535.library import Diamond
from src.zkode.Storage.BFR.IBFR import IBFR
from src.zkode.starkshell.library import Function
from src.bootstrap.IBootstrapper import IBootstrapper, ClassHash

struct BFRCalldata {
    erc721ClassHash: felt,
    bfrClassHash: felt,
    flobDbClassHash: felt,
    starkshellClassHash: felt,
    diamondCutClassHash: felt,
    metadata: felt,
    erc1155ClassHash: felt,
    erc20ClassHash: felt,
    erc5114ClassHash: felt,
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

struct StarkShellCalldata {
    function0: Function,
    function1: Function,
}

struct DiamondCutCalldata {
    null: felt,
}

struct DiamondCalldata {
    root: felt,
    facetKey: felt,
    initFacet: felt,
    bfrFacet: felt,
}

@event
func NewRootDiamond(address: felt) {
}

@constructor
func constructor(_dont_care: felt) {
    return ();
}

@external
func deployRootDiamond{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    _class: ClassHash,
    _setShellFun_selector: felt,
    _setShellFun_compiled_len: felt,
    _setShellFun_compiled: felt*,
    _mintContract_selector: felt,
    _mintContract_compiled_len: felt,
    _mintContract_compiled: felt*,
) -> (rootAddress: felt) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (setShellFun_hash) = hash_chain{hash_ptr=pedersen_ptr}(_setShellFun_compiled);
    let (mintContract_hash) = hash_chain{hash_ptr=pedersen_ptr}(_mintContract_compiled);
    let (block_number) = get_block_number();
    let salt = block_number * caller;

    let (high, low) = split_felt(self);
    let selfTokenId = Uint256(low, high);

    // Deploy a root diamond with self as only facet
    with_attr error_message("UNINITIALIZED DIAMOND CLASS") {
        assert_not_zero(_class.diamond);
    }

    // Root diamonds are created with this contract as their only facet
    local x = _class.diamond;
    with_attr error_message("FAILED DEPLOYMENT x={x}") {
        let (address) = deploy(
            class_hash=_class.diamond,
            contract_address_salt=salt,
            constructor_calldata_size=DiamondCalldata.SIZE,
            constructor_calldata=new (DiamondCalldata(0, 0, _class.rootDiamondFactory, _class.bfr)),
            deploy_from_zero=FALSE,
        );
    }

    IBootstrapper.init(
        address,
        caller,
        selfTokenId,
        _class,
        _setShellFun_selector,
        setShellFun_hash,
        _setShellFun_compiled_len,
        _setShellFun_compiled,
        _mintContract_selector,
        mintContract_hash,
        _mintContract_compiled_len,
        _mintContract_compiled,
    );

    NewRootDiamond.emit(address);

    return (rootAddress=address);
}

// Called as a facet function from RootDiamond
@external
func init{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    _owner: felt,
    _tokenId: Uint256,
    _class: ClassHash,
    _setShellFun_selector: felt,
    _setShellFun_hash: felt,
    _setShellFun_compiled_len: felt,
    _setShellFun_compiled: felt*,
    _mintContract_selector: felt,
    _mintContract_hash: felt,
    _mintContract_compiled_len: felt,
    _mintContract_compiled: felt*,
) -> () {
    alloc_locals;

    let (self) = get_contract_address();
    let (high, low) = split_felt(self);

    let facetCut_len = 6;
    tempvar facetCut: FacetCut* = cast(new (
        FacetCut(_class.bfr, FacetCutAction.Add),
        FacetCut(_class.erc721, FacetCutAction.Add),
        FacetCut(_class.starkshell, FacetCutAction.Add),
        FacetCut(_class.diamondCut, FacetCutAction.Add),
        FacetCut(_class.metadata, FacetCutAction.Add),
        FacetCut(_class.flobDb, FacetCutAction.Add),
        ), FacetCut*);

    let tmp_len = (BFRCalldata.SIZE + 2) + (ERC721Calldata.SIZE + 1) + (StarkShellCalldata.SIZE + 2) + (DiamondCutCalldata.SIZE + 1) + 10;
    tempvar tmp = cast(new (
        BFRCalldata.SIZE + 1,
        BFRCalldata.SIZE,
        BFRCalldata(
            _class.bfr,
            _class.erc721,
            _class.flobDb,
            _class.starkshell,
            _class.diamondCut,
            _class.metadata,
            _class.erc1155,
            _class.erc20,
            _class.erc5114,
            ),
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=_owner,
            tokenId_len=1,
            tokenId_low=low,
            tokenId_high=high,
            ),
        StarkShellCalldata.SIZE + 1,
        2,
        StarkShellCalldata(Function(_setShellFun_selector, _setShellFun_hash, 0), Function(_mintContract_selector, _mintContract_hash, 0)),
        DiamondCutCalldata.SIZE,
        DiamondCutCalldata(0),
        // TODO metadata
        9, 0, 0, 0, 2, 184555836509371486645839001305511529563953210002131601274755952162965647151, 525788472421, FALSE, 0, 0,  // https://www.brilliantblocks.io/zkode
        ), felt*);

    let (local calldata: felt*) = alloc();

    memcpy(calldata, tmp, tmp_len);
    let new_len = tmp_len;

    assert calldata[new_len] = 1 + _setShellFun_compiled_len + _mintContract_compiled_len + 1;
    let new_len = new_len + 1;

    assert calldata[new_len] = 2;
    let new_len = new_len + 1;

    // total array len
    assert calldata[new_len] = _setShellFun_compiled_len + _mintContract_compiled_len;
    let new_len = new_len + 1;

    // memcpy first_array
    memcpy(calldata + new_len, _setShellFun_compiled, _setShellFun_compiled_len);
    let new_len = new_len + _setShellFun_compiled_len;

    // memcpy second array
    memcpy(calldata + new_len, _mintContract_compiled, _mintContract_compiled_len);
    let new_len = new_len + _mintContract_compiled_len;

    let calldata_len = new_len;

    Diamond._diamondCut(facetCut_len, facetCut, calldata_len, calldata);
    let (facet_key) = pow(2, facetCut_len);
    let facet_key = facet_key - 1;

    // Activate configuration
    Diamond._set_root_(self);
    Diamond._set_facet_key_(facet_key);

    // undo write to storage
    Diamond._set_init_root_(0);

    return ();
}

@view
func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    return (res=_el_len);  // TODO does this work? return simply NULL?
}

@view
@raw_output
func __pub_func__() -> (retdata_size: felt, retdata: felt*) {
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
