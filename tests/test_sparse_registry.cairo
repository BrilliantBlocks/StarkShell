%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from src.Register import (
        register,
        resolve,
        calculateKey,
    )

from src.constants import ALL_ONES

from protostar.asserts import (
        assert_eq,
    )


@external
func __setup__{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    # Building sparse registry
    register(0xA)
    register(0xB)
    register(0xC)
    register(0xE)
    register(0xF)
    register(0xD)

    return ()
end


@external
func test_register_duplicate_in_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    %{
        expect_revert(error_message="ELEMENT ALREADY EXISTS")
    %}
    register(0xB)

    return ()
end


@external
func test_register_el_in_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    %{
        expect_events("Register")
    %}
    register(0x7)

    return ()
end


@external
func test_resolve_zero_from_sparse_registry{
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
func test_resolve_all_el_from_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    # ALL_ONES => Get all registry elements
    let (el_len, el) = resolve(ALL_ONES)
    assert_eq(el_len, 6)
    assert_eq(el[0], 0xA)
    assert_eq(el[1], 0xB)
    assert_eq(el[2], 0xC)
    assert_eq(el[3], 0xE)
    assert_eq(el[4], 0xF)
    assert_eq(el[5], 0xD)

    return ()
end


@external
func test_resolve_first_half_el_from_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    # 7 = b000111
    let (el_len, el) = resolve(7)
    assert_eq(el_len, 3)
    assert_eq(el[0], 0xA)
    assert_eq(el[1], 0xB)
    assert_eq(el[2], 0xC)

    return ()
end


@external
func test_resolve_second_half_el_from_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():
    
    # 56 = b111000
    let (el_len, el) = resolve(56)
    assert_eq(el_len, 3)
    assert_eq(el[0], 0xE)  # Note that these elements are not sorted
    assert_eq(el[1], 0xF)
    assert_eq(el[2], 0xD)

    return ()
end


@external
func test_calculating_key_from_empty_el_array_and_sparse_registry{
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
func test_calculating_key_from_single_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local single_el_array: felt*) = alloc()
    let single_el_array_len = 1
    assert single_el_array[0] = 0xE

    let (key) = calculateKey(single_el_array_len, single_el_array)
    assert_eq(key, 8)

    return ()
end


@external
func test_calculating_key_from_multiple_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local single_el_array: felt*) = alloc()
    let single_el_array_len = 3
    assert single_el_array[0] = 0xE
    assert single_el_array[1] = 0xB
    assert single_el_array[2] = 0xD

    let (key) = calculateKey(single_el_array_len, single_el_array)
    assert_eq(key, 42)

    return ()
end


@external
func test_calculating_key_from_all_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local all_el_array: felt*) = alloc()
    let all_el_array_len = 6
    assert all_el_array[0] = 0xA
    assert all_el_array[1] = 0xB
    assert all_el_array[2] = 0xC
    assert all_el_array[3] = 0xF
    assert all_el_array[4] = 0xE
    assert all_el_array[5] = 0xD

    let (key) = calculateKey(all_el_array_len, all_el_array)
    assert_eq(key, 63)

    return ()
end


@external
func test_calculating_key_from_zero_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local single_el_array: felt*) = alloc()
    let single_el_array_len = 3
    assert single_el_array[0] = 0xE
    assert single_el_array[1] = 0x0
    assert single_el_array[2] = 0xD

    %{
        expect_revert(error_message="ZERO ELEMENT")
    %}
    let (key) = calculateKey(single_el_array_len, single_el_array)

    return ()
end


@external
func test_calculating_key_from_unknown_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local single_el_array: felt*) = alloc()
    let single_el_array_len = 3
    assert single_el_array[0] = 0xE
    assert single_el_array[1] = 0x6
    assert single_el_array[2] = 0xD

    %{
        expect_revert(error_message="UNKNOWN ELEMENT")
    %}
    let (key) = calculateKey(single_el_array_len, single_el_array)

    return ()
end


@external
func test_calculating_key_from_overfull_el_array_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local overfull_el_array: felt*) = alloc()
    let overfull_el_array_len = 7
    assert overfull_el_array[0] = 0xE
    assert overfull_el_array[1] = 0xA
    assert overfull_el_array[2] = 0xD
    assert overfull_el_array[3] = 0xF
    assert overfull_el_array[4] = 0xB
    assert overfull_el_array[5] = 0xC
    assert overfull_el_array[6] = 0x6

    %{
        expect_revert(error_message="TOO MANY ELEMENTS")
    %}
    let (key) = calculateKey(overfull_el_array_len, overfull_el_array)

    return ()
end


@external
func test_calculating_key_from_duplicate_el_and_sparse_registry{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():

    alloc_locals

    let (local duplicate_el_array: felt*) = alloc()
    let duplicate_el_array_len = 4
    assert duplicate_el_array[0] = 0xE
    assert duplicate_el_array[1] = 0xA
    assert duplicate_el_array[2] = 0xA
    assert duplicate_el_array[3] = 0xF

    %{
        expect_revert(error_message="DUPLICATE ELEMENT")
    %}
    let (key) = calculateKey(duplicate_el_array_len, duplicate_el_array)

    return ()
end
