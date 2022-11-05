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
from src.zklang.library import Function, Instruction, Primitive, Variable

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User1 = 456;
const User2 = 789;

struct Setup {
    diamond_address: felt,
    repo_address: felt,
    erc1155_class_hash: felt,
    program_hash: felt,
    zklang_class_hash: felt,
    fun_selector_returnCalldata: felt,
    fun_selector_foo: felt,
    setZKLangFun_hash: felt,
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
    local fun_selector_returnCalldata;
    %{ ids.fun_selector_returnCalldata = context.fun_selector_returnCalldata %}
    local fun_selector_foo;
    %{ ids.fun_selector_foo = context.fun_selector_foo %}
    local setZKLangFun_hash;
    %{ ids.setZKLangFun_hash = context.setZKLangFun_hash %}

    local setup: Setup = Setup(
        diamond_address,
        repo_address,
        erc1155_class_hash,
        program_hash,
        zklang_class_hash,
        fun_selector_returnCalldata,
        fun_selector_foo,
        setZKLangFun_hash,
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
    tempvar facetCut: FacetCut* = cast(new (FacetCut(flob_db_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 1;
    tempvar calldata: felt* = new (0);
    let calldata_len = 1;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.TCF_address) %}
    let (repo_address) = ITCF.mintContract(
        TCF_address, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.repo_address = ids.repo_address %}

    // BrilliantBlocks stores diamondAdd in repo
    local return_keyword;
    local var0_identifier;
    local fun_selector_returnCalldata;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.var0_identifier = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        context.fun_selector_returnCalldata = get_selector_from_name("returnCalldata")
        ids.fun_selector_returnCalldata = context.fun_selector_returnCalldata
        context.fun_selector_foo = get_selector_from_name("foo")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);
    // tempvar NULLvar: Variable* = new Variable(0, 0, 0, 0);
    // TODO Optimize for storage, no total count (primitive first, then vars)
    // Diamond.returnCalldata(calldata_len, calldata);
    tempvar instruction0 = Instruction(
        Primitive(0, return_keyword),
        Variable(var0_identifier, 0, 0, 0),
        NULLvar,
        );
    tempvar felt_code: felt* = new (
        1 * Instruction.SIZE,
        instruction0,
        );
    let felt_code_len = felt_code[0] + 1;

    let (program_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.program_hash = ids.program_hash %}

    // BrilliantBlocks stores setZKLangFun in repo
    local fun_selector_setZKLangFun;
    local set_function_keyword;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.set_function_keyword = get_selector_from_name("__ZKLANG__SET_FUNCTION")
        context.fun_selector_setZKLangFun = get_selector_from_name("setZKLangFun")
        ids.fun_selector_setZKLangFun = context.fun_selector_setZKLangFun
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar instruction0 = Instruction(
        Primitive(0, set_function_keyword),
        Variable(var0_identifier, 0, 0, 0),
        NULLvar,
        );
    tempvar instruction1 = Instruction(
        Primitive(0, return_keyword),
        // Variable(var0_identifier, 0, 0, 0),
        NULLvar,  // TODO behavior when missing input?
        NULLvar,
        );
    tempvar felt_code: felt* = new (
        2 * Instruction.SIZE,
        instruction0,
        instruction1,
        );
    let felt_code_len = felt_code[0] + 1;

    let (setZKLangFun_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.setZKLangFun_hash = ids.setZKLangFun_hash %}

    // User1 mints a diamond and adds ERC-1155 and ZKlang
    tempvar facetCut: FacetCut* = cast(new (FacetCut(erc1155_class_hash, FacetCutAction.Add), FacetCut(zklang_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 2;
    tempvar calldata: felt* = new (6, User1, 1, 1, 0, 1, 0, 7, 2, Function(fun_selector_returnCalldata, program_hash, repo_address), Function(fun_selector_setZKLangFun, setZKLangFun_hash, repo_address),);
    let calldata_len = 15;

    %{ stop_prank = start_prank(ids.User1, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(
        TCF_address, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@contract_interface
namespace ITestZKLtuple {
    func returnCalldata(x: felt, y: felt) -> (x_res: felt, y_res: felt) {
    }
}

@contract_interface
namespace ITestZKLarray {
    func returnCalldata(x_len: felt, x: felt*) -> (res_len: felt, res: felt*) {
    }
}

@external
func test_returnCalldata_tuple{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    alloc_locals;
    let setup = getSetup();

    // returnCalldata is recognized as public function
    let (x) = IDiamond.facetAddress(setup.diamond_address, setup.fun_selector_returnCalldata);
    assert_eq(x, setup.zklang_class_hash);

    let (x_res, y_res) = ITestZKLtuple.returnCalldata(setup.diamond_address, 1, 2);
    assert_eq(x_res, 1);
    assert_eq(y_res, 2);

    return ();
}

@external
func test_returnCalldata_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    alloc_locals;
    let setup = getSetup();

    tempvar x: felt* = new (1, 2);
    let x_len = 2;

    let (actual_res_len, actual_res) = ITestZKLarray.returnCalldata(
        setup.diamond_address, x_len, x
    );
    assert_eq(actual_res_len, 2);
    assert_eq(actual_res[0], 1);
    assert_eq(actual_res[1], 2);

    return ();
}

@contract_interface
namespace ITestZKLangFun {
    func setZKLangFun(_fun: Function) -> () {
    }

    func foo(x: felt, y: felt) -> (x_res: felt, y_res: felt) {
    }
}

@external
func test_setZKLangFun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let setup = getSetup();

    tempvar x: Function = Function(setup.fun_selector_foo, setup.program_hash, setup.repo_address);

    ITestZKLangFun.setZKLangFun(setup.diamond_address, x);

    // New zkl function is recognized as public function
    let (facet_hash) = IDiamond.facetAddress(setup.diamond_address, setup.fun_selector_foo);
    assert_eq(facet_hash, setup.zklang_class_hash);

    let (x_res, y_res) = ITestZKLangFun.foo(setup.diamond_address, 3, 4);
    assert_eq(x_res, 3);
    assert_eq(y_res, 4);

    return ();
}
