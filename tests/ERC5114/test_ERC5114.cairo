%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.facets.token.erc5114.structs import NFT

from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.facets.storage.feltmap.IFeltMap import IFeltMap
from src.zkode.facets.token.erc5114.IERC5114 import IERC5114
from src.zkode.interfaces.ITCF import ITCF

from tests.setup import compute_selectors, declare_contracts, deploy_bootstrapper, deploy_root

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct ERC5114Calldata {
    tokenId: Uint256,
    nft: NFT,
}

struct ERC5114Selectors {
    ownerOf: felt,
}

func getERC5114Selectors() -> ERC5114Selectors {
    alloc_locals;
    local ownerOf;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        variables = [
            "ownerOf",
        ]
        [setattr(ids, v, get_selector_from_name(v)) for v in variables]
    %}

    local selectors: ERC5114Selectors = ERC5114Selectors(
        ownerOf,
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

    local erc5114_class;
    %{
        context.erc5114_class = declare("./src/zkode/facets/token/erc5114/ERC5114.cairo").class_hash
        ids.erc5114_class = context.erc5114_class
    %}

    // BrilliantBlocks adds erc5114 to registry
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.root) %}
    IFeltMap.registerElement(root, erc5114_class);
    %{ stop_prank() %}

    // User mints a diamond with ERC5114
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(erc5114_class, FacetCutAction.Add);

    let calldata_len = ERC5114Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC5114Calldata.SIZE,
        ERC5114Calldata(
            tokenId=Uint256(1, 0),
            nft=NFT(0x789, Uint256(2, 0)),
            )
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

    // Assert that initialzation yields expected owner for SBB
    let (nft: NFT) = IERC5114.ownerOf(diamond_address, Uint256(1, 0));
    assert_eq(nft.id.low, 2);
    assert_eq(nft.id.high, 0);
    assert_eq(nft.address, 0x789);

    return ();
}

@external
func test_destructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc5114_class;
    %{ ids.erc5114_class = context.erc5114_class %}

    // Remove ERC5114 facet from diamond
    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(erc5114_class, FacetCutAction.Remove);

    let calldata_len = 1;
    tempvar calldata = new (0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}

@external
func test_getImplementation_return_erc5114{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc5114_class;
    %{ ids.erc5114_class = context.erc5114_class %}

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, erc5114_class);
    return ();
}

@external
func test_erc5114_has_one_function{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc5114_class;
    %{ ids.erc5114_class = context.erc5114_class %}

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(
        diamond_address, erc5114_class
    );
    assert_eq(selectors_len, 1);

    return ();
}

@external
func test_facet_returns_erc5114_for_ownerOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc5114_class;
    %{ ids.erc5114_class = context.erc5114_class %}
    let erc5114 = getERC5114Selectors();

    let (facet) = IDiamond.facetAddress(diamond_address, erc5114.ownerOf);
    assert_eq(facet, erc5114_class);

    return ();
}
