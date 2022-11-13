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

// @external
// func __ZKLANG__RETURN(_res_len: felt, _res: felt*) -> (res_len: felt, res: felt*) {
//     return (_res_len, _res);
// }

@view
@raw_input
func __ZKLANG__RETURN(selector: felt, calldata_size: felt, calldata: felt*) -> (x_len: felt, x: felt*) {
    return (x_len=calldata_size, x=calldata);
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
func __ZKLANG__FELT_TO_UINT256{range_check_ptr}(_x: felt) -> (res: Uint256) {
    let (high, low) = split_felt(_x);

    return (res=Uint256(low, high));
}

@external
func __ZKLANG__CALL_CONTRACT{syscall_ptr: felt*}(_address: felt, _selector: felt, _calldata_len: felt, _calldata: felt*) -> (res_len: felt, res: felt*) {
    alloc_locals;
    // local x0 = _address;
    // local x1 = _selector;
    // local x2 = _calldata_len;
    // with_attr error_message("BREAKPOINT {x0} {x1} {x2}") {
    // with_attr error_message("BREAKPOINT") {
    //     assert 1 = 0;
    // }

    let (res_len, res) = call_contract(
        contract_address=_address,
        function_selector=_selector,
        calldata_size=_calldata_len,
        calldata=_calldata,
    );
    // let (res_len, res) = call_contract(
    //     contract_address=calldata[3],
    //     function_selector=calldata[4],
    //     calldata_size=calldata_size - 4,
    //     calldata=calldata + 4,
    // );
    return (res_len, res);
}

@external
func __ZKLANG__DEPLOY{syscall_ptr: felt*}(_class_hash: felt, _salt: felt, _constructor_calldata_len: felt, _constructor_calldata: felt*) -> (res: felt) {
    alloc_locals;
    local x0 = _class_hash;
    local x1 = _salt;
    local x2 = _constructor_calldata_len;

    with_attr error_message("BREAKPOINT INSIDE DEPLOY PRIMITIVE {x0} {x1} {x2}") {
        let (contract_address) = deploy(
            class_hash=_class_hash,
            contract_address_salt=_salt,
            constructor_calldata_size=_constructor_calldata_len,
            constructor_calldata=_constructor_calldata,
            deploy_from_zero=FALSE,
        );
    }

    return (res=contract_address);
}

@view
@raw_input
func __ZKLANG__NOOP(selector: felt, calldata_size: felt, calldata: felt*) -> (x_len: felt, x: felt*) {
    return (x_len=calldata_size, x=calldata);
}
