%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location

from src.zkode.constants import FUNCTION_SELECTORS

@event
func Store(hash: felt) {
}

@storage_var
func storage_(i: felt) -> (data: felt) {
}

// @emit Store
@external
func store{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _data_len: felt, _data: felt*
) -> (res: felt) {
    alloc_locals;

    // push _data_len on _data and compute hash
    let (local compact_array: felt*) = alloc();
    assert compact_array[0] = _data_len;
    memcpy(compact_array + 1, _data, _data_len);

    let (local hash) = hash_chain{hash_ptr=pedersen_ptr}(compact_array);

    // store _data as felt array beginning with its hash as index
    _store(hash, _data_len, _data);
    // store _data_len at index 0
    storage_.write(hash, _data_len);
    Store.emit(hash);

    return (res=hash);
}

func _store{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _hash: felt, _data_len: felt, _data: felt*
) {
    alloc_locals;

    if (_data_len == 0) {
        return ();
    }

    local last_element: felt = _data[_data_len - 1];
    local offset: felt = _data_len;
    storage_.write(_hash + offset, last_element);

    return _store(_hash, _data_len - 1, _data);
}

@view
func load{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_hash: felt) -> (
    res_len: felt, res: felt*
) {
    let (flob_len) = storage_.read(_hash);
    let (val_len, val) = loadRange(_hash, 0, flob_len - 1);
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
    let (flob_len) = storage_.read(_hash);
    with_attr error_message("OFFSET IS OUT OF RANGE") {
        assert_le(_offset_end, flob_len);
    }
    let (local flob: felt*) = alloc();
    _load(flob, _hash, _offset_start, _offset_end);
    let flob_len = _offset_end - _offset_start + 1;
    return (flob_len, flob);
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
    _flob_count: felt, _data_len: felt, _data: felt*
) -> () {
    alloc_locals;

    if (_flob_count == 0) {
        return ();
    }

    store(_data[0], _data + 1);

    return __constructor__(
        _flob_count=_flob_count - 1, _data_len=_data_len - _data[0] - 1, _data=_data + _data[0] + 1
    );
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
