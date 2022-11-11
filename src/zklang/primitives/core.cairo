%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import call_contract, deploy
from src.ERC2535.library import Diamond

from src.constants import API, FUNCTION_SELECTORS
from src.Storage.IFlobDB import IFlobDB
from src.zklang.library import Program, Memory, State
from src.zklang.structs import Function, Variable

@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*) {
    // TODO syscall
}

@external
func __ZKLANG__RETURN(_res_len: felt, _res: felt*) -> (res_len: felt, res: felt*) {
    return (_res_len, _res);
}

struct Branch {
    x: felt,
    pc_if_true: felt,
    pc_if_false: felt,
}

@external
func __ZKLANG__BRANCH{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _calldata_len: felt, _calldata: felt*
) -> (res_len: felt, res: felt*) {
    assert _calldata_len = Branch.SIZE;
    let branch = cast(_calldata, Branch*);
    if (branch.x == TRUE) {
        tempvar res = new (branch.pc_if_true,);
        return (res_len=1, res=res);
    }
    tempvar res = new (branch.pc_if_false,);
    return (res_len=1, res=res);
}

@external
func __ZKLANG__EVENT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    // TODO How about specifiying args?
    _key: felt, _val_len: felt, _val: felt*
) {
    __ZKLANG__EMIT.emit(_key, _val_len, _val);
    return ();
}

@view
func __ZKLANG__REVERT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    with_attr error_message("__ZKLANG__REVERT") {
        assert 1 = 0;
    }
    return ();
}

@external
func __ZKLANG__SET_FUNCTION{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _calldata_len: felt, _calldata: felt*
) -> () {
    assert _calldata_len = Function.SIZE;
    let fun = cast(_calldata, Function*);
    State.set_fun(fun[0]);
    return ();
}

@external
func __ZKLANG__COMPUTE_HASH{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _calldata_len: felt, _calldata: felt*
) {
    return ();
}

@external
func __ZKLANG__ASSERT_ONLY_OWNER{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    // TODO necessary to have calldata here?
    _calldata_len: felt, _calldata: felt*
) -> () {
    assert _calldata_len = 0;  // This could be redundant?
    Diamond.Assert.only_owner();

    return ();
}

@view
func __ZKLANG__FELT_TO_UINT256{range_check_ptr}(_calldata_len: felt, _calldata: felt*) -> (res: Uint256) {
    assert _calldata_len = 2;
    let (high, low) = split_felt(_calldata[0], _calldata[1]);

    return (res=Uint256(low, high));
}

@external
func __ZKLANG__CALL_CONTRACT{syscall_ptr: felt*}(_calldata_len: felt, _calldata: felt*) -> (res_len: felt, res: felt*) {

    let (res_len, res) = call_contract(
        contract_address=_calldata[0],
        function_selector=_calldata[1],
        calldata_size=_calldata_len - 2,
        calldata=_calldata + 2,
    );
    return (res_len, res);
}

@external
func __ZKLANG__DEPLOY{syscall_ptr: felt*}(_calldata_len: felt, _calldata: felt*) -> (res: felt) {
    let (contract_address) = deploy(
        class_hash=_calldata[0],
        contract_address_salt=_calldata[1],
        constructor_calldata_size=_calldata_len - 2,
        constructor_calldata=_calldata + 2,
        deploy_from_zero=FALSE,
    );

    return (res=contract_address);
}

@view
func __ZKLANG__MERGE_VARS(_calldata_len: felt, _calldata: felt*) -> (res_len: felt, res: felt*) {
    alloc_locals;

    let first_var_len = _calldata[Variable.data_len];
    let second_var_len = _calldata[first_var_len + 1];

    let (local res: felt*) = alloc();
    let res_len = first_var_len + second_var_len;
    memcpy(res, _calldata + 1, first_var_len);
    memcpy(res + first_var_len + 1, _calldata + first_var_len + 1, second_var_len);

    return (res_len, res);
}
