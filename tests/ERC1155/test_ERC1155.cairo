%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.token.erc1155.structs import TokenBatch
from src.zkode.facets.token.erc1155.IERC1155 import IERC1155
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.interfaces.ITCF import ITCF

from tests.setup import (
    ClassHash,
    getClassHashes,
    computeSelectors,
    declareContracts,
    deployRootDiamondFactory,
    deployRootDiamond,
)

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct ERC1155Calldata {
    receiver: felt,
    tokenBatch_len: felt,  // 1
    tokenBatch0: TokenBatch,
}

struct ERC1155Selectors {
    balanceOf: felt,
    balanceOfBatch: felt,
    isApprovedForAll: felt,
    setApprovalForAll: felt,
    safeTransferFrom: felt,
    safeBatchTransferFrom: felt,
}

func getERC1155Selectors() -> ERC1155Selectors {
    alloc_locals;
    local balanceOf;
    local balanceOfBatch;
    local isApprovedForAll;
    local setApprovalForAll;
    local safeTransferFrom;
    local safeBatchTransferFrom;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        variables = [
            "balanceOf",
            "balanceOfBatch",
            "isApprovedForAll",
            "setApprovalForAll",
            "safeTransferFrom",
            "safeBatchTransferFrom",
        ]
        [setattr(ids, v, get_selector_from_name(v)) for v in variables]
    %}

    local selectors: ERC1155Selectors = ERC1155Selectors(
        balanceOf,
        balanceOfBatch,
        isApprovedForAll,
        setApprovalForAll,
        safeTransferFrom,
        safeBatchTransferFrom,
        );

    return selectors;
}

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

    // User mints a diamond with ERC1155
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc1155, FacetCutAction.Add);

    let calldata_len = ERC1155Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC1155Calldata.SIZE,
        ERC1155Calldata(
            receiver=User,
            tokenBatch_len=1,
            tokenBatch0=TokenBatch(
                Uint256(1, 0),
                Uint256(1, 0),
                ),
            ),
        );
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.rootDiamond
        )
    %}
    let (diamond_address) = ITCF.mintContract(
        rootDiamond, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank_callable() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    // Assert that initialzation yields expected balance for User
    let (user_balance: Uint256) = IERC1155.balanceOf(diamond_address, User, Uint256(1, 0));
    assert_eq(user_balance.low, 1);
    assert_eq(user_balance.high, 0);

    return ();
}

@external
func test_destructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    // Remmove ERC1155 facet to diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc1155, FacetCutAction.Remove);

    let calldata_len = 1;
    tempvar calldata = new (0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}

@external
func test_getImplementation_return_erc1155{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, ch.erc1155);

    return ();
}

@external
func test_erc1155_has_six_functions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, ch.erc1155);
    assert_eq(selectors_len, 6);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_balanceOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc1155 = getERC1155Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.balanceOf);
    assert_eq(facet, ch.erc1155);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_balanceOfBatch{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.balanceOfBatch);
    assert_eq(facet, ch.erc1155);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_isApprovedForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.isApprovedForAll);
    assert_eq(facet, ch.erc1155);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_setApprovalForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.setApprovalForAll);
    assert_eq(facet, ch.erc1155);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_safeTransferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.safeTransferFrom);
    assert_eq(facet, ch.erc1155);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_safeBatchTransferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.safeBatchTransferFrom);
    assert_eq(facet, ch.erc1155);

    return ();
}
