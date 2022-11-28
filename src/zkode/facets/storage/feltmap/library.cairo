%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_equal, assert_not_zero
from starkware.cairo.common.pow import pow

const MAX_BITMAP_LENGTH = 251;

@event
func Register(_bitId: felt, _element: felt) {
}

// @dev Map bit to element
@storage_var
func bitmap_(_bitId: felt) -> (_element: felt) {
}

namespace FeltMap {
    func _register_element{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_element: felt) -> () {
        alloc_locals;
        with_attr error_message("ZERO ELEMENT") {
            assert_not_zero(_element);
        }
        // TODO load bitmap as array
        // TODO if not in loaded array: append else noop
        let e = Library._find_first_occurence(_element);
        let first_free_bit = Library._find_first_occurence(0);
        with_attr error_message("DUPLICATE ELEMENT") {
            assert e = first_free_bit;
        }
        with_attr error_message("FULL REGISTRY") {
            assert_le(first_free_bit, MAX_BITMAP_LENGTH - 1);
        }
        bitmap_.write(first_free_bit, _element);
        Register.emit(first_free_bit, _element);
        return ();
    }

    func _register_elements{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_elements_len: felt, _elements: felt*) -> () {
        if (_elements_len == 0) {
            return ();
        }
        _register_element(_elements[0]);
        _register_elements(_elements_len - 1, _elements + 1);
        return ();
    }

    func _calculate_key{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_el_len: felt, _el: felt*) -> felt {
        let key = Library._calculate_key(_el_len, _el, 0);
        return key;
    }

    func _resolve_key{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_key: felt) -> (res_len: felt, res: felt*) {
        alloc_locals;
        let bitmap_len = Library._find_first_occurence(0);
        tempvar i = 0;
        tempvar len = 0;
        let (local res: felt*) = alloc();
        let (res_len) = Library._resolve_key(_key, len, res, i, bitmap_len);
        return (res_len, res);
    }
}

namespace Library {
    func _find_first_occurence{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        target: felt
    ) -> felt {
        return _find_first_occurence_recursion(target, 0);
    }

    func _find_first_occurence_recursion{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(target: felt, _id: felt) -> felt {
        alloc_locals;
        let (el) = bitmap_.read(_id);
        let exit_condition = _reached_end_or_target_found(el, target);
        if (exit_condition == TRUE) {
            return _id;
        }
        return _find_first_occurence_recursion(target, _id + 1);
    }

    // @dev Return TRUE iff (_el == 0) OR (_el == _target)
    func _reached_end_or_target_found(_el, _target) -> felt {
        if (_el * (_target - _el) == 0) {
            return TRUE;
        }
        return FALSE;
    }

    func _resolve_key{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_bit_word: felt, _res_len: felt, _res: felt*, _loop_var: felt, _bitmap_length: felt) -> (
        res_len: felt
    ) {
        if (_loop_var == _bitmap_length) {
            return (_res_len,);
        }
        let (x) = pow(2, _loop_var);
        let (y) = bitwise_and(_bit_word, x);
        if (x == y) {
            let (el) = bitmap_.read(_loop_var);
            assert _res[_res_len] = el;
            return _resolve_key(_bit_word, _res_len + 1, _res, _loop_var + 1, _bitmap_length);
        }
        return _resolve_key(_bit_word, _res_len, _res, _loop_var + 1, _bitmap_length);
    }

    func _calculate_key{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(el_len: felt, el: felt*, sum: felt) -> felt {
        if (el_len == 0) {
            return sum;
        }
        with_attr error_message("ZERO ELEMENT") {
            assert_not_zero(el[0]);
        }
        let a = _find_el_id(el[0], 0);
        let (is_duplicate) = bitwise_and(a, sum);
        with_attr error_message("DUPLICATE ELEMENT") {
            assert is_duplicate = FALSE;
        }
        return _calculate_key(el_len - 1, el + 1, sum + a);
    }

    func _find_el_id{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_el: felt, _id: felt) -> felt {
        alloc_locals;
        let l = _find_first_occurence(0);  // Bitmap length
        with_attr error_message("UNKNOWN ELEMENT") {
            assert_not_equal(_id, l);
        }
        let (x) = bitmap_.read(_id);
        if (x == _el) {
            let (z) = pow(2, _id);
            return z;
        }
        return _find_el_id(_el, _id + 1);
    }
}
