%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from src.ERC2535.library import Diamond

from src.constants import API, FUNCTION_SELECTORS
from src.Storage.IFlobDB import IFlobDB
from src.zklang.library import Program, Memory, State
from src.zklang.structs import Function


@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*) {
}

@external
func __ZKLANG__RETURN{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _res_len: felt, _res: felt*
) -> (res_len: felt, res: felt*) {
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
