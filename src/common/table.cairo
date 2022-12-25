from starkware.cairo.common.memcpy import memcpy

namespace Table {
    // @return New length of _table
    func add_row(_table_len: felt, _table: felt*, _row_len: felt, _row: felt*) -> felt {
        assert _table[_table_len] = _row_len;
        let _table_len = _table_len + 1;

        memcpy(_table + _table_len, _row, _row_len);
        let _table_len = _table_len + _row_len;

        return _table_len;
    }
}
