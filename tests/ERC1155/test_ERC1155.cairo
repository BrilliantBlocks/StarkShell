%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.storage.feltmap.IFeltMap import IFeltMap
from src.zkode.facets.token.erc1155.structs import TokenBatch
from src.zkode.facets.token.erc1155.IERC1155 import IERC1155
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.interfaces.ITCF import ITCF

from tests.setup import compute_selectors, declare_contracts, deploy_bootstrapper, deploy_root

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

    compute_selectors();
    declare_contracts();
    deploy_bootstrapper();
    deploy_root();

    local root;
    %{ ids.root = context.root %}

    local erc1155_class;
    %{
        context.erc1155_class = declare("./src/zkode/facets/token/erc1155/ERC1155.cairo").class_hash
        ids.erc1155_class = context.erc1155_class
    %}

    // BrilliantBlocks adds erc1155 to registry
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.root) %}
    IFeltMap.registerElement(root, erc1155_class);
    %{ stop_prank() %}

    // User mints a diamond with ERC1155
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(erc1155_class, FacetCutAction.Add);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    // Remmove ERC1155 facet to diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(erc1155_class, FacetCutAction.Remove);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, erc1155_class);

    return ();
}

@external
func test_erc1155_has_six_functions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(
        diamond_address, erc1155_class
    );
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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}
    let erc1155 = getERC1155Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.balanceOf);
    assert_eq(facet, erc1155_class);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.balanceOfBatch);
    assert_eq(facet, erc1155_class);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.isApprovedForAll);
    assert_eq(facet, erc1155_class);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.setApprovalForAll);
    assert_eq(facet, erc1155_class);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.safeTransferFrom);
    assert_eq(facet, erc1155_class);

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
    local erc1155_class;
    %{ ids.erc1155_class = context.erc1155_class %}

    let (facet) = IDiamond.facetAddress(diamond_address, erc1155.safeBatchTransferFrom);
    assert_eq(facet, erc1155_class);

    return ();
}
