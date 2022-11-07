%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
from src.Storage.IFlobDB import IFlobDB
from src.zklang.IZKlang import IZKlang
from src.zklang.library import Function

from tests.zklang.fun.invertBoolean import invertBoolean
from tests.zklang.fun.returnCalldata import returnCalldata
from tests.zklang.fun.setZKLangFun import setZKLangFun
from tests.zklang.fun.interpreteInstruction import interpreteInstruction

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

    let (felt_code_len, felt_code) = returnCalldata();
    let (program_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.program_hash = ids.program_hash %}

    let (felt_code_len, felt_code) = setZKLangFun();
    let (setZKLangFun_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.setZKLangFun_hash = ids.setZKLangFun_hash %}

    let (felt_code_len, felt_code) = invertBoolean();
    let (invertBoolean_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.invertBoolean_hash = ids.invertBoolean_hash %}

    let (felt_code_len, felt_code) = interpreteInstruction();
    let (interpretInstruction_hash) = IFlobDB.store(repo_address, felt_code_len, felt_code);
    %{ context.interpretInstruction_hash = ids.interpretInstruction_hash %}

    local fun_selector_returnCalldata;
    local fun_selector_setZKLangFun;
    local fun_selector_invertBoolean;
    local fun_selector_interpreteInstruction;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        context.fun_selector_returnCalldata = get_selector_from_name("returnCalldata")
        ids.fun_selector_returnCalldata = context.fun_selector_returnCalldata
        context.fun_selector_setZKLangFun = get_selector_from_name("setZKLangFun")
        ids.fun_selector_setZKLangFun = context.fun_selector_setZKLangFun
        context.fun_selector_foo = get_selector_from_name("foo")
        ids.fun_selector_invertBoolean = get_selector_from_name("invertBoolean")
        ids.fun_selector_interpreteInstruction = get_selector_from_name("interpreteInstruction")
    %}

    // User1 mints a diamond and adds ERC-1155 and ZKlang
    tempvar facetCut: FacetCut* = cast(new (FacetCut(erc1155_class_hash, FacetCutAction.Add), FacetCut(zklang_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 2;
    tempvar calldata: felt* = new (6, User1, 1, 1, 0, 1, 0, 10, 3, Function(fun_selector_returnCalldata, program_hash, repo_address), Function(fun_selector_setZKLangFun, setZKLangFun_hash, repo_address), Function(fun_selector_invertBoolean, invertBoolean_hash, repo_address), Function(fun_selector_interpreteInstruction, interpretInstruction_hash, repo_address),);
    let calldata_len = 18;

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

    func invertBoolean(_bool: felt) -> (_invertedBool: felt) {
    }

    func interpreteInstruction(
        _pid: felt, _program_len: felt, _program: felt*, _memory_len: felt, _memory: felt*
    ) -> (res_len: felt, res: felt*) {
    }
}

@external
func test_setZKLangFun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let setup = getSetup();

    tempvar x: Function = Function(setup.fun_selector_foo, setup.program_hash, setup.repo_address);

    %{ stop_prank = start_prank(ids.User1, context.diamond_address) %}
    ITestZKLangFun.setZKLangFun(setup.diamond_address, x);
    %{ stop_prank() %}

    // New zkl function is recognized as public function
    let (facet_hash) = IDiamond.facetAddress(setup.diamond_address, setup.fun_selector_foo);
    assert_eq(facet_hash, setup.zklang_class_hash);

    let (x_res, y_res) = ITestZKLangFun.foo(setup.diamond_address, 3, 4);
    assert_eq(x_res, 3);
    assert_eq(y_res, 4);

    return ();
}

@external
func test_setZKLangFun_reverts_if_caller_not_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let setup = getSetup();

    tempvar x: Function = Function(setup.fun_selector_foo, setup.program_hash, setup.repo_address);

    %{ stop_prank = start_prank(ids.User2, context.diamond_address) %}
    %{ expect_revert(error_message="NOT AUTHORIZED") %}
    ITestZKLangFun.setZKLangFun(setup.diamond_address, x);
    %{ stop_prank() %}

    return ();
}

@external
func test_invertBoolean_returns_true_on_false{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let setup = getSetup();

    let (actual_res) = ITestZKLangFun.invertBoolean(setup.diamond_address, FALSE);
    let expected_res = TRUE;
    assert_eq(actual_res, expected_res);

    return ();
}

@external
func test_invertBoolean_returns_false_on_true{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let setup = getSetup();

    let (actual_res) = ITestZKLangFun.invertBoolean(setup.diamond_address, TRUE);
    let expected_res = FALSE;
    assert_eq(actual_res, expected_res);

    return ();
}
