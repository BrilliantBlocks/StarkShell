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
from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.diamond.library import Diamond
from src.zkode.facets.storage.feltmap.IFeltMap import IFeltMap
from src.zkode.facets.starkshell.library import Function
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
    function2: Function,
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
    _updateMetadata_selector: felt,
    _updateMetadata_compiled_len: felt,
    _updateMetadata_compiled: felt*,
) -> (rootAddress: felt) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (self) = get_contract_address();
    let (setShellFun_hash) = hash_chain{hash_ptr=pedersen_ptr}(_setShellFun_compiled);
    let (mintContract_hash) = hash_chain{hash_ptr=pedersen_ptr}(_mintContract_compiled);
    let (updateMetadata_hash) = hash_chain{hash_ptr=pedersen_ptr}(_updateMetadata_compiled);

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
            constructor_calldata=new (DiamondCalldata(0, 0, _class.rootDiamondFactory, _class.feltmap)),
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
        _updateMetadata_selector,
        updateMetadata_hash,
        _updateMetadata_compiled_len,
        _updateMetadata_compiled,
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
    _updateMetadata_selector: felt,
    _updateMetadata_hash: felt,
    _updateMetadata_compiled_len: felt,
    _updateMetadata_compiled: felt*,
) -> () {
    alloc_locals;

    let (self) = get_contract_address();
    let (high, low) = split_felt(self);

    let facetCut_len = 6;
    tempvar facetCut: FacetCut* = cast(new (
        FacetCut(_class.feltmap, FacetCutAction.Add),
        FacetCut(_class.erc721, FacetCutAction.Add),
        FacetCut(_class.starkshell, FacetCutAction.Add),
        FacetCut(_class.diamondCut, FacetCutAction.Add),
        FacetCut(_class.metadata, FacetCutAction.Add),
        FacetCut(_class.flobDb, FacetCutAction.Add),
        ), FacetCut*);

    let tmp_len = (BFRCalldata.SIZE + 2) + (ERC721Calldata.SIZE + 1) + (StarkShellCalldata.SIZE + 2 + 9) + (DiamondCutCalldata.SIZE + 1) + 12;
    tempvar tmp = cast(new (
        BFRCalldata.SIZE + 1,
        BFRCalldata.SIZE,
        BFRCalldata(
            _class.feltmap,
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
        StarkShellCalldata.SIZE + 1 + 9,
        3,
        StarkShellCalldata(
            Function(_setShellFun_selector, _setShellFun_hash, 0),
            Function(_mintContract_selector, _mintContract_hash, 0),
            Function(_updateMetadata_selector, _updateMetadata_hash, 0)
            ),
        8,
        0,  // setShellFun params_len
        0,  // mintContract params_len
        5,  // updateMetadata params_len
        // ### Begin Variable ###
        465330906121207756919483712490106284233474427241768683713250428177289303613,
        0,
        0,
        1,
        1528802474226268325865027367859591458315299653151958663884057507666229546336,
        // ### End Variable ###
        DiamondCutCalldata.SIZE,
        DiamondCutCalldata(0),
        // ### Metadata ###
        11,
        0,  // don't care
        0,  // don't care
        0,  // don't care
        4,  // https://m4chgvnjpozvm7p7jeo7vj3susfrkuencv6j5bf3u6mokcshjmeq.arweave.net/ZwRzVal7s1Z9_0kd-qdypIsVUI0VfJ6Eu6eY5QpHSwk
        184555836509371486644856095017587421344261193474617388276263770152936827443,
        203998027954878725543997547266317984232748597657159516903365148909254028897,
        202244606418614541364902086132942206699045874315590809968639424267107263609,
        10754949894223100254076072945295018243026244912222009195,
        FALSE,  // no infix
        0,  // no suffix
        0,  // don't care
        ), felt*);

    let (local calldata: felt*) = alloc();

    memcpy(calldata, tmp, tmp_len);
    let new_len = tmp_len;

    assert calldata[new_len] = 1 + _setShellFun_compiled_len + _mintContract_compiled_len + _updateMetadata_compiled_len + 1;
    let new_len = new_len + 1;

    assert calldata[new_len] = 3;
    let new_len = new_len + 1;

    // total array len
    assert calldata[new_len] = _setShellFun_compiled_len + _mintContract_compiled_len + _updateMetadata_compiled_len;
    let new_len = new_len + 1;

    // memcpy first_array
    memcpy(calldata + new_len, _setShellFun_compiled, _setShellFun_compiled_len);
    let new_len = new_len + _setShellFun_compiled_len;

    // memcpy second array
    memcpy(calldata + new_len, _mintContract_compiled, _mintContract_compiled_len);
    let new_len = new_len + _mintContract_compiled_len;

    // memcpy third array
    memcpy(calldata + new_len, _updateMetadata_compiled, _updateMetadata_compiled_len);
    let new_len = new_len + _updateMetadata_compiled_len;

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

// @dev Required interface subset of BFR
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
    dw FUNCTION_SELECTORS.IBootstrapper.init;
    dw FUNCTION_SELECTORS.IFeltMap.calculateKey;
}
