%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
from src.Storage.IFlobDB import IFlobDB
from src.zklang.IZKlang import IZKlang

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;

struct Setup {
    diamond_address: felt,
    repo_address: felt,
    erc1155_class_hash: felt,
    program_hash: felt,
    zklang_class_hash: felt,
}

func getSetup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Setup {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local repo_address;
    %{ ids.repo_address = context.repo_address %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}
    local program_hash;
    %{ ids.program_hash = context.program_hash %}
    local zklang_class_hash;
    %{ ids.zklang_class_hash = context.zklang_class_hash %}

    local setup: Setup = Setup(
        diamond_address,
        repo_address,
        erc1155_class_hash,
        program_hash,
        zklang_class_hash,
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
    local flob_db_class_hash;
    %{
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash;
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.zklang_class_hash = declare("./src/zklang/ZKlang.cairo").class_hash
        ids.zklang_class_hash = context.zklang_class_hash
        context.flob_db_class_hash = declare("./src/Storage/FlobDB.cairo").class_hash
        ids.flob_db_class_hash = context.flob_db_class_hash
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
    tempvar elements: felt* = new (diamondCut_class_hash, erc1155_class_hash, zklang_class_hash, flob_db_class_hash);
    let elements_len = 4;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // BrilliantBlocks mints a repo diamond
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.TCF_address) %}
    let (repo_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    tempvar facetCut: FacetCut* = cast(new (FacetCut(flob_db_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (0);
    let calldata_len = 1;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, ids.repo_address) %}
    IDiamondCut.diamondCut(repo_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    %{ context.repo_address = ids.repo_address %}

    // BrilliantBlocks stores diamondAdd in repo
    local add_keyword;
    local return_keyword;
    local var_keyword;
    local var1_identifier;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.add_keyword = get_selector_from_name("__ZKLANG__ADD")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.var_keyword = get_selector_from_name("__ZKLANG__SET_VAR")
        ids.var1_identifier = get_selector_from_name("var1")
    %}

    // Diamond.add(7, 8);
    // tempvar felt_code: felt* = new (
    //     // var foo = x + y
    //     10,
    //     5, // instruction_len
    //     0, // zklang core
    //     var_keyword,
    //     7, // var1_identifier,
    //     add_keyword,
    //     0, // input is calldata

    //     // return foo
    //     3, // instruction_len
    //     0, // zklang core
    //     return_keyword,
    //     var1_identifier,
    // );
    tempvar felt_code: felt* = new (
        14,
        6,
        0,
        var1_identifier,
        0,
        add_keyword,
        1,
        0,
        6,
        2,
        0,
        0,
        return_keyword,
        0,
        var1_identifier,
        );
    let felt_code_len = 15;
    let (program_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.program_hash = ids.program_hash %}

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
    tempvar calldata: felt* = new (1, 0);
    let calldata_len = 2;

    // User adds ZKlang facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@contract_interface
namespace IDiamondCalc {
    func diamondAdd(x: felt, y: felt) -> (res: felt) {
    }
}

@external
func test_deploy_zklang_function{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let setup = getSetup();
    local my_func_selector;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.my_func_selector = get_selector_from_name("diamondAdd")
    %}

    // IZKlang.deployFunction(
    //     setup.diamond_address, my_func_selector, setup.program_hash, setup.repo_address
    // );

    // // diamondAdd is recognized as public function
    // let (x) = IDiamond.facetAddress(setup.diamond_address, my_func_selector);
    // assert_eq(x, setup.zklang_class_hash);

    // // program has expected format
    // let (program_len, program) = IFlobDB.load(setup.repo_address, setup.program_hash);
    // // assert_eq(program_len, 10);
    // // assert_eq(program[0], 5);
    // // assert_eq(program[program[0]+1], 3);
    // assert_eq(program_len, 14);
    // assert_eq(program[0], 6);
    // assert_eq(program[program[0] + 1], 6);

    // let (res) = IDiamondCalc.diamondAdd(setup.diamond_address, 7, 9);
    // assert_eq(res, 16);

    return ();
}
