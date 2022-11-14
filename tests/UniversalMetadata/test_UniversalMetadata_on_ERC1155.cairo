%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.interfaces.IBFR import IBFR
from src.interfaces.ITCF import ITCF

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

    let ch: ClassHash = getClassHashes();

    // User mints a diamond with UniversalMetadata and ERC-1155
    tempvar facetCut: FacetCut* = cast(new (FacetCut(ch.metadata, FacetCutAction.Add), FacetCut(ch.erc1155, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 2;
    tempvar calldata: felt* = new (7, 0, 0, 0, 0, 0, 0, 0, 6, User, 1, 1, 0, 1, 0,);
    let calldata_len = 15;

    %{ stop_prank = start_prank(ids.User, ids.rootDiamond) %}
    let (diamond_address) = ITCF.mintContract(
        rootDiamond, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_facetFunctionSelectors_returns_one_selector{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, ch.metadata);
    assert_eq(selectors_len, 1);

    return ();
}

@external
func test_facetAddress_of_uri_returns_universal_metadata_class_hash{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    local uri;
    %{ from starkware.starknet.public.abi import get_selector_from_name %}
    %{ ids.uri = get_selector_from_name("uri") %}

    let (actual_facet) = IDiamond.facetAddress(diamond_address, uri);
    assert_eq(actual_facet, ch.metadata);

    return ();
}

@external
func test_supportsInterface_returns_true_on_erc1155_without_token_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    const IERC1155_METADATA_ID = 0x0e89341c;
    let (supportsIERC1155) = IDiamond.supportsInterface(diamond_address, IERC1155_METADATA_ID);
    assert_eq(supportsIERC1155, TRUE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc20_without_token_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    const IERC20_METADATA_ID = 0x942e8b22;
    let (supportsIERC20) = IDiamond.supportsInterface(diamond_address, IERC20_METADATA_ID);
    assert_eq(supportsIERC20, FALSE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc721_without_token_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    const IERC721_METADATA_ID = 0x5b5e139f;
    let (supportsIERC721) = IDiamond.supportsInterface(diamond_address, IERC721_METADATA_ID);
    assert_eq(supportsIERC721, FALSE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc5114_without_token_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    const IERC5114_METADATA_ID = 0x6cea869c;
    let (supportsIERC5114) = IDiamond.supportsInterface(diamond_address, IERC5114_METADATA_ID);
    assert_eq(supportsIERC5114, FALSE);
    return ();
}
