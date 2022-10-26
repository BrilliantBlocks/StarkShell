%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.UniversalMetadata.IUniversalMetadata import IERC1155Metadata
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;


struct Setup {
    diamond_address: felt,
    erc1155_class_hash: felt,
}

func getSetup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Setup {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}
    local arithmetic_class_hash;
    %{ ids.arithmetic_class_hash = context.arithmetic_class_hash %}

    local setup: Setup = Setup(
        diamond_address,
        erc1155_class_hash,
    );
    return setup;
}


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local diamondCut_class_hash;
    local universalMetadata_class_hash;
    local erc1155_class_hash;
    local zklang_class_hash;
    local arithmetic_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash;
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.zklang_class_hash = declare("./src/zklang/ZKlang.cairo").class_hash
        ids.zklang_class_hash = context.zklang_class_hash
        context.arithmetic_class_hash = declare("./src/zklang/Arithmetic.zklang.cairo").class_hash
        ids.arithmetic_class_hash = context.arithmetic_class_hash
    %}
    
    local TCF_address;
    %{  
        # Deploy BFR and TCF
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
        ids.TCF_address = context.TCF_address
    %}

    // BrilliantBlocks populates facet registry
    tempvar elements: felt* = new (diamondCut_class_hash, erc1155_class_hash, zklang_class_hash, arithmetic_class_hash);
    let elements_len = 4;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    tempvar facetCut: FacetCut* = cast(new (FacetCut(erc1155_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (6, User, 1, 1, 0, 1, 0);
    let calldata_len = 7;

    // User adds ERC-1155 facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    tempvar facetCut: FacetCut* = cast(new (FacetCut(zklang_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (0);
    let calldata_len = 1;

    // User adds ZKlang facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@contract_interface
namespace IZKlang {
    func deployFunction(_selector: felt, _code_len: felt, _code: felt*) -> () {
    }

    func deleteFunction(_selector: felt) -> () {
    }
}

@external
func test_deployFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local my_func_selector;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.my_func_selector = get_selector_from_name("my_func")
    %}
    let setup = getSetup();

    let (local felt_code: felt*) = alloc();
    assert felt_code[0] = 1;
    assert felt_code[1] = 2;
    assert felt_code[2] = 3;
    let felt_code_len = 3;
    IZKlang.deployFunction(setup.diamond_address, my_func_selector, felt_code_len, felt_code);

    return ();
}
