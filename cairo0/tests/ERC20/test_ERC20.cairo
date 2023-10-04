%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.components.diamond.structs import FacetCut, FacetCutAction

from src.components.diamond.IDiamond import IDiamond
from src.components.facets.upgradability.IDiamondCut import IDiamondCut
from src.components.facets.token.erc20.IERC20 import IERC20
from src.components.interfaces.ITCF import ITCF

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
const Adversary = 789;

struct ERC20Calldata {
    receiver: felt,
    balance: Uint256,
}

struct ERC20Selectors {
    balanceOf: felt,
    totalSupply: felt,
    transfer: felt,
    approve: felt,
    allowance: felt,
    transferFrom: felt,
    increaseAllowance: felt,
    decreaseAllowance: felt,
}

func getERC20Selectors() -> ERC20Selectors {
    alloc_locals;
    local balanceOf;
    local totalSupply;
    local transfer;
    local approve;
    local allowance;
    local transferFrom;
    local increaseAllowance;
    local decreaseAllowance;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        variables = [
            "balanceOf",
            "totalSupply",
            "transfer",
            "approve",
            "allowance",
            "transferFrom",
            "increaseAllowance",
            "decreaseAllowance",
        ]
        [setattr(ids, v, get_selector_from_name(v)) for v in variables]
    %}

    local selectors: ERC20Selectors = ERC20Selectors(
        balanceOf,
        totalSupply,
        transfer,
        approve,
        allowance,
        transferFrom,
        increaseAllowance,
        decreaseAllowance,
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

    // User mints a diamond with ERC20
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc20, FacetCutAction.Add);

    let calldata_len = ERC20Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC20Calldata.SIZE,
        ERC20Calldata(receiver=User, balance=Uint256(1000000, 0))
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
    let (user_balance: Uint256) = IERC20.balanceOf(diamond_address, User);
    assert_eq(user_balance.low, 1000000);
    assert_eq(user_balance.high, 0);

    return ();
}

@external
func test_destructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    // Remove ERC20 facet from diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc20, FacetCutAction.Remove);

    let calldata_len = 1;
    tempvar calldata = new (0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}

@external
func test_getImplementation_return_erc20{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, ch.erc20);

    return ();
}

@external
func test_erc20_has_eight_functions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, ch.erc20);
    assert_eq(selectors_len, 8);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_balanceOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.balanceOf);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_totalSupply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.totalSupply);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_approve{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.approve);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_allowance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.allowance);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_transfer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.transfer);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_transferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.transferFrom);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_increaseAllowance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.increaseAllowance);
    assert_eq(facet, ch.erc20);

    return ();
}

@external
func test_facetAddress_returns_erc20_for_decreaseAllowance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();
    let erc20 = getERC20Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc20.decreaseAllowance);
    assert_eq(facet, ch.erc20);

    return ();
}
