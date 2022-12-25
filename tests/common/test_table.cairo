%lang starknet
from starkware.cairo.common.alloc import alloc

from src.common.table import Table

from protostar.asserts import assert_eq

@external
func test_append_empty_array_to_empty_array() {
    alloc_locals;

    let (local table: felt*) = alloc();
    let (local row: felt*) = alloc();

    local table_len = 0;
    local row_len = 0;

    let table_len = Table.add_row(table_len, table, row_len, row);

    assert_eq(table_len, 1);
    assert_eq(table[0], 0);

    return ();
}

@external
func test_append_empty_array_to_non_empty_array() {
    alloc_locals;

    let (local table: felt*) = alloc();
    let (local row: felt*) = alloc();

    assert table[0] = 2;
    assert table[1] = 11;
    assert table[2] = 12;

    local table_len = 3;
    local row_len = 0;

    let table_len = Table.add_row(table_len, table, row_len, row);

    assert_eq(table_len, 4);
    assert_eq(table[0], 2);
    assert_eq(table[1], 11);
    assert_eq(table[2], 12);
    assert_eq(table[3], 0);

    return ();
}

@external
func test_append_non_empty_array_to_empty_array() {
    alloc_locals;

    let (local table: felt*) = alloc();
    let (local row: felt*) = alloc();

    assert row[0] = 11;
    assert row[1] = 12;
    assert row[2] = 13;

    local table_len = 0;
    local row_len = 3;

    let table_len = Table.add_row(table_len, table, row_len, row);

    assert_eq(table_len, 4);
    assert_eq(table[0], 3);
    assert_eq(table[1], 11);
    assert_eq(table[2], 12);
    assert_eq(table[3], 13);

    return ();
}

@external
func test_append_non_empty_array_to_non_empty_array() {
    alloc_locals;

    let (local table: felt*) = alloc();
    let (local row: felt*) = alloc();

    assert table[0] = 0;

    assert row[0] = 11;
    assert row[1] = 12;
    assert row[2] = 13;

    local table_len = 1;
    local row_len = 3;

    let table_len = Table.add_row(table_len, table, row_len, row);

    assert_eq(table_len, 5);
    assert_eq(table[0], 0);
    assert_eq(table[1], 3);
    assert_eq(table[2], 11);
    assert_eq(table[3], 12);
    assert_eq(table[4], 13);

    return ();
}
