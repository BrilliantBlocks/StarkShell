%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, assert_not_equal

from src.Power2 import power_of_2

const MAX_BITMAP_LENGTH = 251


@event
func AddMapping(bit_id: felt, class_hash):
end


@storage_var
func bitmap(bit_id: felt) -> (res: felt):
end


@external
func addElementToBitmap{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        element: felt,    
    ) -> ():

    let (first_free_slot_id) = _find_first_zero()

    with_attr error_msg("FULL BITMAP"):
        assert_le(first_free_slot_id, MAX_BITMAP_LENGTH)
    end

    bitmap.write(first_free_slot_id, element)
    AddMapping.emit(first_free_slot_id, element)

    return ()
end


@view
func getBitmapLength{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (
        res: felt
    ):

    let (bitmap_length) = _find_first_zero()
    
    return (bitmap_length)
end


func _find_first_zero{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (res: felt):

    return _find_first_zero_helper(0)
end


func _find_first_zero_helper{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _id: felt    
    ) -> (
        res: felt
    ):

    let (el) = bitmap.read(_id)
    
    if el == 0:
        return (_id)
    end

    return _find_first_zero_helper(_id + 1)
end


@view
func resolveBitWord{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        bit_word: felt,
    ) -> (
        res_len: felt,
        res: felt*,
    ):
    alloc_locals

    let (bitmap_length) = getBitmapLength()

    let (local res: felt*) = alloc()

    tempvar i = 0
    tempvar len = 0
    let (res_len) = _resolve_bit_word(bit_word, len, res, i, bitmap_length)

    return (res_len, res)
end


func _resolve_bit_word{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_bit_word: felt, _res_len: felt, _res: felt*, _loop_var: felt, _bitmap_length: felt) -> (res_len: felt):
    if _loop_var == _bitmap_length:
        return(_res_len)
    end

    let (x) = power_of_2(_loop_var)
    let (y) = bitwise_and(_bit_word, x)
    
    if x == y:
        let (el) = bitmap.read(_loop_var)
        assert _res[_res_len] = el

        return _resolve_bit_word(_bit_word, _res_len + 1, _res, _loop_var + 1, _bitmap_length)
    end

    return _resolve_bit_word(_bit_word, _res_len, _res, _loop_var + 1, _bitmap_length)
end


@view
func calculateBitWord{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        el_len: felt,
        el: felt*,
    ) -> (
        res: felt,
    ):

    return  _calculate_bitword(el_len, el, 0)
end


func _calculate_bitword{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        el_len: felt,
        el: felt*,
        sum: felt,
    ) -> (
        res: felt,
    ):

    if el_len == 0:
        return (sum + 0)
    end

    let (a) = _find_el(el[0], 0)

    return _calculate_bitword(el_len - 1, el + 1, sum + a)
end


func _find_el{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_el: felt, _id: felt) -> (res_len: felt):
    alloc_locals

    with_attr error_msg("WORD NOT IN LANGUAGE"):
        let (l) = getBitmapLength()
        assert_not_equal(_id, l)
    end

    let (x) = bitmap.read(_id)

    if x == _el:
        let (z) = power_of_2(_id)
        return (z)
    end

    return _find_el(_el, _id + 1)
end
