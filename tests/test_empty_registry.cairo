%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from src.Register import (
        calculateKey,
        resolve,
    )

from tests.constants import ALL_ONES

from protostar.asserts import (
        assert_eq,
    )


@external
func test_resolving_zero_from_empty_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    let (el_len, el) = resolve(0)
    assert_eq(el_len, 0)

    return ()
end


@external
func test_resolving_all_el_from_empty_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    # ALL_ONES => Get all registry elements
    let (el_len, el) = resolve(ALL_ONES)
    assert_eq(el_len, 0)

    return ()
end


@external
func test_calculating_key_from_empty_el_array_and_empty_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local empty_el_array: felt*) = alloc()
    let empty_el_array_len = 0

    %{
        expect_revert(error_message="EMPTY ARRAY")
    %}
    let (key) = calculateKey(empty_el_array_len, empty_el_array)

    return ()
end


@external
func test_calculating_key_from_nonzero_el_and_empty_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local nonzero_el_array: felt*) = alloc()
    let nonzero_el_array_len = 1
    assert nonzero_el_array[0] = 0xA

    %{
        expect_revert(error_message="TOO MANY ELEMENTS")
    %}
    let (key) = calculateKey(nonzero_el_array_len, nonzero_el_array)

    return ()
end


@external
func test_calculating_key_from_zero_el_and_empty_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local nonzero_el_array: felt*) = alloc()
    let nonzero_el_array_len = 1
    assert nonzero_el_array[0] = 0x0

    %{
        expect_revert(error_message="TOO MANY ELEMENTS")
    %}
    let (key) = calculateKey(nonzero_el_array_len, nonzero_el_array)

    return ()
end
