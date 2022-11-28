%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.registers import get_label_location

from onlydust.stream.default_implementation import stream

from src.zkode.constants import FUNCTION_SELECTORS

@event
func Store(hash: felt) {
}

@storage_var
func storage_(i: felt) -> (data: felt) {
}

// @dev Always reset to zero
@storage_var
func storage_internal_temp_var() -> (res: felt) {
}

// @notice _felt_code[0] = _felt_code_len
@external
func store{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _data_len: felt, _data: felt*
) -> (res: felt) {
    alloc_locals;

    let (hash) = hash_chain{hash_ptr=pedersen_ptr}(_data);
    storage_internal_temp_var.write(hash);
    stream.foreach(_storeCell, _data_len, _data);
    storage_internal_temp_var.write(0);
    Store.emit(hash);

    return (res=hash);
}

func _storeCell{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, element: felt*
) {
    let (hash) = storage_internal_temp_var.read();
    let (data) = storage_.read(hash + index);
    with_attr error_message("OVERWRITE CELL") {
        assert data = 0;
    }
    storage_.write(hash + index, element[0]);
    return ();
}

@view
func load{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_hash: felt) -> (
    res_len: felt, res: felt*
) {
    let (blob_len) = storage_.read(_hash);
    let (val_len, val) = loadRange(_hash, 0, blob_len - 1);
    return (val_len, val);
}

func _load{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _ptr: felt*, _hash: felt, _offset_start: felt, _offset_end: felt
) {
    alloc_locals;
    let (data) = storage_.read(_hash + _offset_start + 1);
    assert _ptr[0] = data;
    if (_offset_start == _offset_end) {
        return ();
    } else {
        return _load(_ptr + 1, _hash, _offset_start + 1, _offset_end);
    }
}

@view
func loadRange{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _hash: felt, _offset_start: felt, _offset_end: felt
) -> (res_len: felt, res: felt*) {
    alloc_locals;
    with_attr error_message(
            "INVALID OFFSETS hash={_hash} start={_offset_start} < end={_offset_end}") {
        assert_le(_offset_start, _offset_end);
    }
    let (blob_len) = storage_.read(_hash);
    with_attr error_message("OFFSET IS OUT OF RANGE") {
        assert_le(_offset_end, blob_len);
    }
    let (local blob: felt*) = alloc();
    _load(blob, _hash, _offset_start, _offset_end);
    let blob_len = _offset_end - _offset_start + 1;
    return (blob_len, blob);
}

@view
func loadCell{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _hash: felt, _offset: felt
) -> (res: felt) {
    let (val_le, val) = loadRange(_hash, _offset, _offset);
    return (res=val[0]);
}

// ===================
// Mandatory functions
// ===================

// @dev Initialize this facet
@external
func __constructor__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _n: felt, _data_len: felt, _data: felt*
) -> () {
    if (_n == 0) {
        return ();
    }

    store(_data[0], _data);

    return __constructor__(_n - 1, _data_len - _data[0] - 1, _data + _data[0] + 1);
}

// @dev Remove this facet
@external
func __destructor__() -> () {
    return ();
}

// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __pub_func__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    retdata_size: felt, retdata: felt*
) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=4, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.STORAGE.store;
    dw FUNCTION_SELECTORS.STORAGE.load;
    dw FUNCTION_SELECTORS.STORAGE.loadCell;
    dw FUNCTION_SELECTORS.STORAGE.loadRange;
}

// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
