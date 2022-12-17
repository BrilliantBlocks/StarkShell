%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction

from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.facets.token.erc721.IERC721 import IERC721
from src.zkode.interfaces.ITCF import ITCF

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
const Adversary = 789;

struct ERC721Calldata {
    receiver: felt,
    tokenId_len: felt,  // 2
    tokenId0: Uint256,
    tokenId1: Uint256,
}

struct ERC721Selectors {
    approve: felt,
    balanceOf: felt,
    getApproved: felt,
    isApprovedForAll: felt,
    ownerOf: felt,
    safeTransferFrom: felt,
    setApprovalForAll: felt,
    transferFrom: felt,
}

func getERC721Selectors() -> ERC721Selectors {
    alloc_locals;
    local approve;
    local balanceOf;
    local getApproved;
    local isApprovedForAll;
    local ownerOf;
    local safeTransferFrom;
    local setApprovalForAll;
    local transferFrom;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        variables = [
            "approve",
            "balanceOf",
            "getApproved",
            "isApprovedForAll",
            "ownerOf",
            "safeTransferFrom",
            "setApprovalForAll",
            "transferFrom",
        ]
        [setattr(ids, v, get_selector_from_name(v)) for v in variables]
    %}

    local selectors: ERC721Selectors = ERC721Selectors(
        approve,
        balanceOf,
        getApproved,
        isApprovedForAll,
        ownerOf,
        safeTransferFrom,
        setApprovalForAll,
        transferFrom,
        );

    return selectors;
}

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

    let ch: ClassHash = get_class_hashes();

    // User mints a diamond with ERC721
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc721, FacetCutAction.Add);

    let calldata_len = ERC721Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=User,
            tokenId_len=2,
            tokenId0=Uint256(1, 0),
            tokenId1=Uint256(3, 0),
            ),
        );

    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.root
        )
    %}
    let (diamond_address) = ITCF.mintContract(root, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank_callable() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    // Assert that initialzation yields expected token for user
    let (owner: felt) = IERC721.ownerOf(diamond_address, Uint256(1, 0));
    assert_eq(owner, User);

    let (owner: felt) = IERC721.ownerOf(diamond_address, Uint256(3, 0));
    assert_eq(owner, User);

    return ();
}

@external
func test_destructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();

    // Remove ERC721 facet from diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc721, FacetCutAction.Remove);

    let calldata_len = 1;
    tempvar calldata = new (0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}

@external
func test_getImplementation_return_erc721{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, ch.erc721);

    return ();
}

@external
func test_erc721_has_eight_functions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, ch.erc721);
    assert_eq(selectors_len, 8);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_balanceOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.balanceOf);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_ownerOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.ownerOf);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_getApproved{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.getApproved);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_isApprovedForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.isApprovedForAll);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_approve{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.approve);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_setApprovalForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.setApprovalForAll);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_transferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.transferFrom);
    assert_eq(facet, ch.erc721);

    return ();
}

@external
func test_facetAddress_returns_erc721_for_safeTransferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();
    let erc721 = getERC721Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc721.safeTransferFrom);
    assert_eq(facet, ch.erc721);

    return ();
}
