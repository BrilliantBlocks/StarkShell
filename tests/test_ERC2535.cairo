%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local diamondCut_class_hash;
    local erc721_class_hash;
    %{
        ids.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.erc721_class_hash = declare("./src/ERC721/ERC721.cairo").class_hash
        ids.erc721_class_hash = context.erc721_class_hash;
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    ids.BFR_address,
                    0, # name
                    0, # symbol
                    1, # uri_len
                    1, # uri
                ],
            ).contract_address
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=ids.BFR_address
        )
    %}
    let (local elements: felt*) = alloc();
    assert elements[0] = diamondCut_class_hash;
    assert elements[1] = erc721_class_hash;
    IBFR.registerElements(BFR_address, 2, elements);
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_diamondCut_remove_diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    local erc721_class_hash;
    local diamondCut_class_hash;
    %{
        ids.TCF_address = context.TCF_address;
        ids.erc721_class_hash = context.erc721_class_hash;
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.TCF_address
        )
    %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank_callable() %}

    // The minted diamond has 1 facets
    let (facets_len: felt, facets: felt*) = IDiamond.facetAddresses(diamond_address);
    assert_eq(facets_len, 1);

    let (local NULLptr: felt*) = alloc();
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.diamond_address
        )
    %}
    // IDiamondCut.diamondCut(diamond_address, diamondCut_class_hash, 1, FALSE, 0, NULLptr);
    let (x: FacetCut*) = alloc();
    assert x[0].facetAddress = diamondCut_class_hash;
    assert x[0].facetCutAction = FacetCutAction.Remove;
    IDiamondCut.diamondCut(diamond_address, 1, x, 0, NULLptr);
    %{ stop_prank_callable() %}
    let (facets_len: felt, facets: felt*) = IDiamond.facetAddresses(diamond_address);
    assert_eq(facets_len, 0);
    return ();
}

@external
func test_diamondCut_add_erc721{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    local erc721_class_hash;
    local diamondCut_class_hash;
    %{
        ids.TCF_address = context.TCF_address;
        ids.erc721_class_hash = context.erc721_class_hash;
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.TCF_address
        )
    %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank_callable() %}

    // The minted diamond has 1 facets
    let (facets_len: felt, facets: felt*) = IDiamond.facetAddresses(diamond_address);
    assert_eq(facets_len, 1);

    let (local NULLptr: felt*) = alloc();
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.diamond_address
        )
    %}
    // IDiamondCut.diamondCut(diamond_address, erc721_class_hash, 0, FALSE, 0, NULLptr);
    let (x: FacetCut*) = alloc();
    assert x[0].facetAddress = erc721_class_hash;
    assert x[0].facetCutAction = FacetCutAction.Add;
    IDiamondCut.diamondCut(diamond_address, 1, x, 0, NULLptr);
    %{ stop_prank_callable() %}
    let (facets_len: felt, facets: felt*) = IDiamond.facetAddresses(diamond_address);
    assert_eq(facets_len, 2);
    
    // The minted diamond is detected as ERC721
    let (implementation_hash: felt) = IDiamond.getImplementation(diamond_address);
    assert_eq(implementation_hash, erc721_class_hash);

    return ();
}
