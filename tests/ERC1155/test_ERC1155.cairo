%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC1155.IERC1155 import TokenBatch
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

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

struct Setup {
    diamond_address: felt,
    diamond_class_hash: felt,
    diamondCut_class_hash: felt,
    erc1155_class_hash: felt,
    BFR_address: felt,
    TCF_address: felt,
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

func getSetup() -> Setup {
    alloc_locals;
    local diamond_address;
    local diamond_class_hash;
    local diamondCut_class_hash;
    local erc1155_class_hash;
    local BFR_address;
    local TCF_address;

    %{
        variables = [
            "diamond_address",
            "diamond_class_hash",
            "diamondCut_class_hash",
            "erc1155_class_hash",
            "BFR_address",
            "TCF_address",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local setup: Setup = Setup(
        diamond_address,
        diamond_class_hash,
        diamondCut_class_hash,
        erc1155_class_hash,
        BFR_address,
        TCF_address,
        );

    return setup;
}

func declareContracts() -> () {
    %{
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
    %}

    return ();
}

func deployContracts() -> () {
    %{
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
    %}

    return ();
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    declareContracts();
    deployContracts();
    let setup = getSetup();

    // BrilliantBlocks populates facet registry
    let elements_len = 2;
    tempvar elements = new (setup.diamondCut_class_hash, setup.erc1155_class_hash);
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(setup.TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a diamond with ERC1155
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(setup.erc1155_class_hash, FacetCutAction.Add);

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

    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(
        setup.TCF_address, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();

    // Assert that initialzation yields expected balance for User
    let (user_balance: Uint256) = IERC1155.balanceOf(setup.diamond_address, User, Uint256(1, 0));
    assert_eq(user_balance.low, 1);
    assert_eq(user_balance.high, 0);

    return ();
}

@external
func test_destructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();

    // Remmove ERC1155 facet to diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(setup.erc1155_class_hash, FacetCutAction.Remove);

    let calldata_len = 1;
    tempvar calldata = new (0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(setup.diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}

@external
func test_getImplementation_return_erc1155{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let setup = getSetup();

    let (token_class_hash) = IDiamond.getImplementation(setup.diamond_address);
    assert_eq(token_class_hash, setup.erc1155_class_hash);
    return ();
}

@external
func test_erc1155_has_six_functions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let setup = getSetup();

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(
        setup.diamond_address, setup.erc1155_class_hash
    );
    assert_eq(selectors_len, 6);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_balanceOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.balanceOf);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_balanceOfBatch{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.balanceOfBatch);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_isApprovedForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.isApprovedForAll);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_setApprovalForAll{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.setApprovalForAll);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_safeTransferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.safeTransferFrom);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}

@external
func test_facetAddress_returns_erc1155_for_safeBatchTransferFrom{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let erc1155 = getERC1155Selectors();
    let setup = getSetup();

    let (facet) = IDiamond.facetAddress(setup.diamond_address, erc1155.safeBatchTransferFrom);
    assert_eq(facet, setup.erc1155_class_hash);

    return ();
}
