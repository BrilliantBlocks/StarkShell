%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain

from src.ERC2535.structs import FacetCut, FacetCutAction
from src.zklang.structs import Function, Instruction, Primitive, Variable

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import IDiamondCut
from src.interfaces.IBFR import IBFR
from src.interfaces.ITCF import ITCF
from src.Storage.IFlobDB import IFlobDB

from tests.zklang.fun.invertBoolean import invertBoolean
from tests.zklang.fun.returnCalldata import returnCalldata
from tests.zklang.fun.setZKLangFun import setZKLangFun
from tests.zklang.fun.interpreteInstruction import interpreteInstruction

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
const User1 = 456;
const User2 = 789;

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

    // BrilliantBlocks store functions in root diamond
    let (felt_code_len, felt_code) = returnCalldata();
    let (program_hash) = IFlobDB.store(rootDiamond, felt_code_len, felt_code);
    %{ context.program_hash = ids.program_hash %}

    // setZKLangFun already included in repo
    let (_, felt_code) = setZKLangFun();
    let (setZKLangFun_hash) = hash_chain{hash_ptr=pedersen_ptr}(felt_code);

    let (felt_code_len, felt_code) = invertBoolean();
    let (invertBoolean_hash) = IFlobDB.store(rootDiamond, felt_code_len, felt_code);
    %{ context.invertBoolean_hash = ids.invertBoolean_hash %}

    let (felt_code_len, felt_code) = interpreteInstruction();
    let (interpreteInstruction_hash) = IFlobDB.store(rootDiamond, felt_code_len, felt_code);
    %{ context.interpreteInstruction_hash = ids.interpreteInstruction_hash %}

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
    let facetCut_len = 2;
    tempvar facetCut: FacetCut* = cast(new (FacetCut(ch.erc1155, FacetCutAction.Add), FacetCut(ch.zklang, FacetCutAction.Add),), FacetCut*);

    tempvar fun_returnCalldata = Function(fun_selector_returnCalldata, program_hash, rootDiamond);
    tempvar fun_setZKLangFun = Function(fun_selector_setZKLangFun, setZKLangFun_hash, rootDiamond);
    tempvar fun_invertBoolean = Function(fun_selector_invertBoolean, invertBoolean_hash, rootDiamond);
    tempvar fun_interpreteInstruction = Function(fun_selector_interpreteInstruction, interpreteInstruction_hash, rootDiamond);
    local fun_len = 4;
    local fun_calldata_size = fun_len * Function.SIZE + 1;

    tempvar calldata: felt* = new (
        6, User1, 1, 1, 0, 1, 0,
        fun_calldata_size,
        fun_len,
        fun_returnCalldata,
        fun_setZKLangFun,
        fun_invertBoolean,
        fun_interpreteInstruction,
        );
    let calldata_len = 7 + fun_calldata_size + 1;

    %{ stop_prank = start_prank(ids.User1, context.rootDiamond) %}
    let (diamond_address) = ITCF.mintContract(
        rootDiamond, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}
    %{ print(context.rootDiamond) %}
    %{ print(context.diamond_address) %}

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
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local fun_selector_returnCalldata;
    %{ ids.fun_selector_returnCalldata = context.fun_selector_returnCalldata %}
    local rootDiamond;
    %{ ids.rootDiamond = context.rootDiamond %}
    let ch: ClassHash = getClassHashes();

    // returnCalldata is recognized as public function
    let (x) = IDiamond.facetAddress(diamond_address, fun_selector_returnCalldata);
    assert_eq(x, ch.zklang);

    let (x_res, y_res) = ITestZKLtuple.returnCalldata(diamond_address, 1, 2);
    assert_eq(x_res, 1);
    assert_eq(y_res, 2);

    return ();
}

@external
func test_returnCalldata_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar x: felt* = new (1, 2);
    let x_len = 2;

    let (actual_res_len, actual_res) = ITestZKLarray.returnCalldata(diamond_address, x_len, x);
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
        _program_len: felt, _program: felt*, _memory_len: felt, _memory: felt*
    ) -> (res_len: felt, res: felt*) {
    }
}

@external
func test_setZKLangFun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local fun_selector_foo;
    %{ ids.fun_selector_foo = context.fun_selector_foo %}
    let ch: ClassHash = getClassHashes();
    local program_hash;
    %{ ids.program_hash = context.program_hash %}
    local rootDiamond;
    %{ ids.rootDiamond = context.rootDiamond %}

    tempvar x: Function = Function(fun_selector_foo, program_hash, rootDiamond);

    %{ stop_prank = start_prank(ids.User1, context.diamond_address) %}
    ITestZKLangFun.setZKLangFun(diamond_address, x);
    %{ stop_prank() %}

    // New zkl function is recognized as public function
    let (facet_hash) = IDiamond.facetAddress(diamond_address, fun_selector_foo);
    assert_eq(facet_hash, ch.zklang);

    let (x_res, y_res) = ITestZKLangFun.foo(diamond_address, 3, 4);
    assert_eq(x_res, 3);
    assert_eq(y_res, 4);

    return ();
}

@external
func test_setZKLangFun_reverts_if_caller_not_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local fun_selector_foo;
    %{ ids.fun_selector_foo = context.fun_selector_foo %}
    local program_hash;
    %{ ids.program_hash = context.program_hash %}
    local rootDiamond;
    %{ ids.rootDiamond = context.rootDiamond %}

    tempvar x: Function = Function(fun_selector_foo, program_hash, rootDiamond);

    %{ stop_prank = start_prank(ids.User2, context.diamond_address) %}
    %{ expect_revert(error_message="NOT AUTHORIZED") %}
    ITestZKLangFun.setZKLangFun(diamond_address, x);
    %{ stop_prank() %}

    return ();
}

@external
func test_invertBoolean_returns_true_on_false{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    let (actual_res) = ITestZKLangFun.invertBoolean(diamond_address, FALSE);
    let expected_res = TRUE;
    assert_eq(actual_res, expected_res);

    return ();
}

@external
func test_invertBoolean_returns_false_on_true{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    let (actual_res) = ITestZKLangFun.invertBoolean(diamond_address, TRUE);
    let expected_res = FALSE;
    assert_eq(actual_res, expected_res);

    return ();
}

@external
func test_interpreteInstruction_reverts_if_caller_not_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    tempvar program = new ();
    tempvar memory = new ();

    local program_len = 0;
    local memory_len = 0;

    %{ stop_prank = start_prank(ids.User2, context.diamond_address) %}
    %{ expect_revert(error_message="NOT AUTHORIZED") %}
    ITestZKLangFun.interpreteInstruction(diamond_address, program_len, program, memory_len, memory);
    %{ stop_prank() %}

    return ();
}

@external
func test_interpreteInstruction_returnCalldata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = getClassHashes();

    local return_keyword;
    local calldata_id;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.calldata_id = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar Calldata = Variable(calldata_id, 0, 0, 0);

    tempvar instruction0 = Instruction(
        primitive=Primitive(ch.zklang, return_keyword),
        input1=Calldata,
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar Calldata = Variable(calldata_id, 0, 0, 2);
    tempvar program = new (instruction0);
    tempvar memory = new (Calldata, 3, 4);

    local program_len = 1 * Instruction.SIZE;
    local memory_len = 1 * Variable.SIZE + Calldata.data_len;

    %{ stop_prank = start_prank(ids.User1, context.diamond_address) %}
    let (res_len, res) = ITestZKLangFun.interpreteInstruction(
        diamond_address, program_len, program, memory_len, memory
    );
    %{ stop_prank() %}
    assert_eq(res_len, 2);
    assert_eq(res[0], 3);
    assert_eq(res[1], 4);

    return ();
}
