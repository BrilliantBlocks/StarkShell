%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.ERC2535.IDiamondCut import IDiamondCut, FacetCut
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
from src.constants import NULL

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local diamondCut_class_hash;
    %{
        context.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        ids.BFR_address = context.BFR_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash;
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    ids.BFR_address,
                    0, # name
                    0, # symbol
                    0, # uri_len
                ],
            ).contract_address
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=ids.BFR_address
        )
    %}
    IBFR.registerElement(BFR_address, diamondCut_class_hash);
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_mintContract{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    let (local NULLptr: felt*) = alloc();
    let (local FCNULLptr: FacetCut*) = alloc();
    local TCF_address;
    local diamondCut_class_hash;
    %{
        ids.TCF_address = context.TCF_address;
        ids.diamondCut_class_hash = context.diamondCut_class_hash;
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.TCF_address
        )
    %}
    let (diamond_address) = ITCF.mintContract(TCF_address, NULL, FCNULLptr, NULL, NULLptr);
    %{ stop_prank_callable() %}

    // Minted diamond has only DiamondCut
    let (facets_len: felt, facets: felt*) = IDiamond.facetAddresses(diamond_address);
    assert_eq(facets_len, 1);
    assert_eq(facets[0], diamondCut_class_hash);
    
    return ();
}
