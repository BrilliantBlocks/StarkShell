%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from src.Facets import (
        addElementToBitmap,
        getBitmapLength,
        resolveBitWord,
        calculateBitWord,
    )

from protostar.asserts import (
        assert_eq,
    )


@external
func __setup__():
    %{
        context.contract_address  = deploy_contract("./src/Facets.cairo").contract_address
    %}

    return ()
end

@external
func test_empty_bitmap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    let expected_len = 0
    let (actual_len) = getBitmapLength()
    assert_eq(actual_len, expected_len)

    return ()
end


@external
func test_add_first_element_to_bitmap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    addElementToBitmap(0xA)

    let expected_len = 1
    let (actual_len) = getBitmapLength()
    assert_eq(actual_len, expected_len)

    let (word_len, word) = resolveBitWord(1)
    assert_eq(word_len, 1)
    assert_eq(word[0], 0xA)

    return ()
end


@external
func test_add_second_element_to_bitmap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    addElementToBitmap(0xB)
    addElementToBitmap(0xC)

    let expected_len = 2
    let (actual_len) = getBitmapLength()
    assert_eq(actual_len, expected_len)

    let (word_len, word) = resolveBitWord(0)
    assert_eq(word_len, 0)

    let (word_len, word) = resolveBitWord(1)
    assert_eq(word_len, 1)
    assert_eq(word[0], 0xB)

    let (word_len, word) = resolveBitWord(2)
    assert_eq(word_len, 1)
    assert_eq(word[0], 0xC)

    let (word_len, word) = resolveBitWord(3)
    assert_eq(word_len, 2)
    assert_eq(word[0], 0xB)
    assert_eq(word[1], 0xC)

    let (local facet: felt*) = alloc()
    assert facet[0] = 0xC
    assert facet[1] = 0xB
    let (my_word) = calculateBitWord(2, facet)
    assert_eq(my_word, 3)

    return ()
end
