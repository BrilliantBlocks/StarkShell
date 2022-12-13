%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import call_contract, deploy, emit_event

from src.zkode.diamond.library import Diamond
from src.zkode.facets.starkshell.library import State
from src.zkode.facets.starkshell.structs import Function, Variable

@view
@raw_input
func __ZKLANG__RETURN(selector: felt, calldata_size: felt, calldata: felt*) -> (
    x_len: felt, x: felt*
) {
    return (x_len=calldata_size, x=calldata);
}

@view
func __ZKLANG__FILTER_VAR(_start: felt, _end: felt, _x_len: felt, _x: felt*) -> (
    res_len: felt, res: felt*
) {
    alloc_locals;

    let (local ptr: felt*) = alloc();
    local ptr_len = _end - _start;

    memcpy(ptr, _x + _start, ptr_len);

    return (ptr_len, ptr);
}

@external
func __ZKLANG__BRANCH{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: felt, pc_if_true: felt, pc_if_false: felt
) -> (res_len: felt, res: felt*) {
    if (x == TRUE) {
        tempvar res = new (pc_if_true,);
        return (res_len=1, res=res);
    }

    tempvar res = new (pc_if_false,);
    return (res_len=1, res=res);
}

@external
func __ZKLANG__EVENT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    //( _key: felt, _val_len: felt, _val: felt*
    _val_len: felt, _val: felt*
) {
    alloc_locals;

    // tempvar key = new (_key);
    tempvar key = new (1528802474226268325865027367859591458315299653151958663884057507666229546336);
    local key_len = 1;
    emit_event(key_len, key, _val_len, _val);

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
    _function: Function, _params_len: felt, _params: felt*
) -> () {
    State.set_fun(_function, _params_len, _params);

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
    ) -> () {
    Diamond.Assert.only_owner();

    return ();
}

@external
func __ZKLANG__ASSERT_EQ{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _x: felt, _y: felt
) -> () {
    assert _x = _y;

    return ();
}

@view
func __ZKLANG__FELT_TO_UINT256{range_check_ptr}(_x: felt) -> (res: Uint256) {
    let (high, low) = split_felt(_x);

    return (res=Uint256(low, high));
}

@view
func __ZKLANG__ADD(_x: felt, _y: felt) -> (res: felt) {
    return (res=_x + _y);
}

@view
func __ZKLANG__SUB(_x: felt, _y: felt) -> (res: felt) {
    return (res=_x - _y);
}

@view
func __ZKLANG__MUL(_x: felt, _y: felt) -> (res: felt) {
    return (res=_x * _y);
}

@view
func __ZKLANG__DIV(_x: felt, _y: felt) -> (res: felt) {
    return (res=_x / _y);
}

@external
func __ZKLANG__CALL_CONTRACT{syscall_ptr: felt*}(
    _address: felt, _selector: felt, _calldata_len: felt, _calldata: felt*
) -> (res_len: felt, res: felt*) {
    with_attr error_message("CALL CONTRACT {_address} {_selector} {_calldata_len}") {
        let (res_len, res) = call_contract(
            contract_address=_address,
            function_selector=_selector,
            calldata_size=_calldata_len,
            calldata=_calldata,
        );
    }

    return (res_len, res);
}

@external
func __ZKLANG__DEPLOY{syscall_ptr: felt*}(
    _class_hash: felt, _salt: felt, _constructor_calldata_len: felt, _constructor_calldata: felt*
) -> (res: felt) {
    let (contract_address) = deploy(
        class_hash=_class_hash,
        contract_address_salt=_salt,
        constructor_calldata_size=_constructor_calldata_len,
        constructor_calldata=_constructor_calldata,
        deploy_from_zero=FALSE,
    );

    return (res=contract_address);
}

@view
@raw_input
func __ZKLANG__NOOP(selector: felt, calldata_size: felt, calldata: felt*) -> (
    x_len: felt, x: felt*
) {
    return (x_len=calldata_size, x=calldata);
}
