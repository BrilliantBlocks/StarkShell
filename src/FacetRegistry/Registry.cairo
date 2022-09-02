%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import (
        assert_le,
        assert_not_equal,
        assert_not_zero,
    )
from starkware.starknet.common.syscalls import (
        get_caller_address,
        get_contract_address,
    )
from starkware.cairo.common.uint256 import Uint256

from src.power_of_two import power_of_2
from src.storage import bitmap
from src.token.ERC721.IERC721 import IERC721


const MAX_BITMAP_LENGTH = 251


# @dev Emit when new element is added to storage
# @param id in bitmap, stored element
@event
func Register(_bitId: felt, _element: felt):
end


# @dev Register element in bitmap
# @revert Duplicate elements
# @revert Full registry
# @param Element to add
@external
func register{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _element: felt,    
    ) -> ():
    alloc_locals
    # TODO only valid facets can be stored

    let (self) = get_contract_address()
    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(self, Uint256(0,0))

    with_attr error_message("You must be the owner to call the function"):
        assert caller = owner
    end

    let (e) = _find_first(_element)
    let (first_free_bit) = _find_first(0)

    with_attr error_message("ELEMENT ALREADY EXISTS"):
        assert e = first_free_bit
    end

    with_attr error_message("FULL REGISTRY"):
        assert_le(first_free_bit, MAX_BITMAP_LENGTH - 1)
    end

    bitmap.write(first_free_bit, _element)
    Register.emit(first_free_bit, _element)

    return ()
end


func _find_first{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(target: felt) -> (res: felt):

    return _find_first_helper(target, 0)
end


func _find_first_helper{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        target: felt,
        _id: felt,
    ) -> (
        res: felt
    ):

    let (el) = bitmap.read(_id)
    
    if el == 0:
        return (_id)
    end

    if el == target:
        return (_id)
    end

    return _find_first_helper(target, _id + 1)
end


# @dev Resolve bitword
# @param bitword
# @return Array of stored elements
@view
func resolve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _key: felt,
    ) -> (
        res_len: felt,
        res: felt*,
    ):
    alloc_locals

    # assert 4 = 0
    let (bitmap_len) = _find_first(0)

    let (local res: felt*) = alloc()

    tempvar i = 0
    tempvar len = 0
    let (res_len) = _resolve_bit_word(_key, len, res, i, bitmap_len)

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


# @dev Calculate bitword given an array of elements
# @param Array of ELEMENTS
# @return Bitword
@view
func calculateKey{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _el_len: felt,
        _el: felt*,
    ) -> (
        res: felt,
    ):

    with_attr error_message("EMPTY ARRAY"):
        assert_not_zero(_el_len)
    end

    let (bitmap_len) = _find_first(0)
    with_attr error_message("TOO MANY ELEMENTS {_el_len} {bitmap_len}"):
        assert_le(_el_len, bitmap_len)
    end

    return  _calculate_key(_el_len, _el, 0)
end


func _calculate_key{
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

    with_attr error_message("ZERO ELEMENT"):
        assert_not_zero(el[0])
    end

    let (a) = _find_el(el[0], 0)

    let (is_duplicate) = bitwise_and(a, sum)
    with_attr error_message("DUPLICATE ELEMENT"):
        assert is_duplicate = FALSE
    end

    return _calculate_key(el_len - 1, el + 1, sum + a)
end


func _find_el{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_el: felt, _id: felt) -> (res_len: felt):
    alloc_locals

    let (l) = _find_first(0) # Bitmap length
    with_attr error_message("UNKNOWN ELEMENT"):
        assert_not_equal(_id, l)
    end

    let (x) = bitmap.read(_id)

    if x == _el:
        let (z) = power_of_2(_id)
        return (z)
    end

    return _find_el(_el, _id + 1)
end
