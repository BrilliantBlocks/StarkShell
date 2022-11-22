%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.zkode.constants import API
from src.zkode.starkshell.library import Memory
from src.zkode.starkshell.structs import DataTypes, Variable

from protostar.asserts import assert_eq, assert_not_eq

@external
func test_init_memory_on_empty_calldata_and_empty_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new ();
    let _calldata_len = 0;
    tempvar _memory = new ();
    let _memory_len = 0;
    let (local expected_memory: felt*) = alloc();
    let expected_memory_len = 0;

    tempvar calldata_var = new Variable(API.CORE.__ZKLANG__CALLDATA_VAR, FALSE, DataTypes.FELT, _calldata_len);
    tempvar calldata_var_len = Variable.SIZE + calldata_var.data_len;
    memcpy(expected_memory + expected_memory_len, calldata_var, calldata_var_len);
    tempvar expected_memory_len = expected_memory_len + calldata_var_len;

    tempvar caller_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar caller_address_var_len = Variable.SIZE + caller_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, caller_address_var, caller_address_var_len);
    tempvar expected_memory_len = expected_memory_len + caller_address_var_len;

    tempvar contract_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar contract_address_var_len = Variable.SIZE + contract_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, contract_address_var, contract_address_var_len);
    tempvar expected_memory_len = expected_memory_len + contract_address_var_len;

    let (actual_memory_len, actual_memory) = Memory.init(
        _memory_len, _memory, _calldata_len, _calldata
    );

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);

    assert_eq(
        actual_memory[Variable.SIZE + Variable.selector],
        expected_memory[Variable.SIZE + Variable.selector],
    );
    assert_eq(
        actual_memory[Variable.SIZE + Variable.protected],
        expected_memory[Variable.SIZE + Variable.protected],
    );
    assert_eq(
        actual_memory[Variable.SIZE + Variable.type], expected_memory[Variable.SIZE + Variable.type]
    );
    assert_eq(
        actual_memory[Variable.SIZE + Variable.data_len],
        expected_memory[Variable.SIZE + Variable.data_len],
    );

    return ();
}

@external
func test_init_memory_on_non_single_width_calldata_on_empty_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new (7);
    let _calldata_len = 1;
    tempvar _memory = new ();
    let _memory_len = 0;
    let (local expected_memory: felt*) = alloc();
    let expected_memory_len = 0;

    tempvar calldata_var = new Variable(API.CORE.__ZKLANG__CALLDATA_VAR, FALSE, DataTypes.FELT, _calldata_len);
    tempvar calldata_var_len = Variable.SIZE + calldata_var.data_len;
    memcpy(expected_memory + expected_memory_len, calldata_var, Variable.SIZE);
    memcpy(expected_memory + expected_memory_len + Variable.SIZE, _calldata, _calldata_len);
    tempvar expected_memory_len = expected_memory_len + calldata_var_len;

    tempvar caller_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar caller_address_data = new (0x7);
    tempvar caller_address_var_len = Variable.SIZE + caller_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, caller_address_var, Variable.SIZE);
    memcpy(
        expected_memory + expected_memory_len + Variable.SIZE,
        caller_address_data,
        caller_address_var.data_len,
    );
    tempvar expected_memory_len = expected_memory_len + caller_address_var_len;

    tempvar contract_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar caller_address_data = new (0x13);
    tempvar contract_address_var_len = Variable.SIZE + contract_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, contract_address_var, Variable.SIZE);
    memcpy(
        expected_memory + expected_memory_len + Variable.SIZE,
        caller_address_data,
        contract_address_var.data_len,
    );
    tempvar expected_memory_len = expected_memory_len + contract_address_var_len;

    let (actual_memory_len, actual_memory) = Memory.init(
        _memory_len, _memory, _calldata_len, _calldata
    );

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);
    assert_eq(actual_memory[Variable.data_len + 1], expected_memory[Variable.data_len + 1]);

    return ();
}

@external
func test_init_memory_on_calldata_with_five_elements_on_empty_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new (7, 0, -1, 9, 0);
    let _calldata_len = 5;
    tempvar _memory = new ();
    let _memory_len = 0;
    let (local expected_memory: felt*) = alloc();
    let expected_memory_len = 0;

    tempvar calldata_var = new Variable(API.CORE.__ZKLANG__CALLDATA_VAR, FALSE, DataTypes.FELT, _calldata_len);
    tempvar calldata_var_len = Variable.SIZE + calldata_var.data_len;
    memcpy(expected_memory + expected_memory_len, calldata_var, Variable.SIZE);
    memcpy(expected_memory + expected_memory_len + Variable.SIZE, _calldata, _calldata_len);
    tempvar expected_memory_len = expected_memory_len + calldata_var_len;

    tempvar caller_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar caller_address_data = new (0x7);
    tempvar caller_address_var_len = Variable.SIZE + caller_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, caller_address_var, Variable.SIZE);
    memcpy(
        expected_memory + expected_memory_len + Variable.SIZE,
        caller_address_data,
        caller_address_var.data_len,
    );
    tempvar expected_memory_len = expected_memory_len + caller_address_var_len;

    tempvar contract_address_var = new Variable(API.CORE.__ZKLANG__CALLER_ADDRESS_VAR, TRUE, DataTypes.FELT, 1);
    tempvar contract_address_data = new (0x7);
    tempvar caller_address_var_len = Variable.SIZE + contract_address_var.data_len;
    memcpy(expected_memory + expected_memory_len, contract_address_var, Variable.SIZE);
    memcpy(
        expected_memory + expected_memory_len + Variable.SIZE,
        contract_address_data,
        contract_address_var.data_len,
    );
    tempvar expected_memory_len = expected_memory_len + caller_address_var_len;

    let (actual_memory_len, actual_memory) = Memory.init(
        _memory_len, _memory, _calldata_len, _calldata
    );

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);
    assert_eq(actual_memory[Variable.data_len + 1], expected_memory[Variable.data_len + 1]);
    assert_eq(actual_memory[Variable.data_len + 2], expected_memory[Variable.data_len + 2]);
    assert_eq(actual_memory[Variable.data_len + 3], expected_memory[Variable.data_len + 3]);
    assert_eq(actual_memory[Variable.data_len + 4], expected_memory[Variable.data_len + 4]);
    assert_eq(actual_memory[Variable.data_len + 5], expected_memory[Variable.data_len + 5]);

    return ();
}

@external
func test_is_variable_in_memory_returns_true_if_var_in_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=var0.selector, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, TRUE);

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=var1.selector, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, TRUE);

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=var2.selector, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, TRUE);

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=var3.selector, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, TRUE);

    return ();
}

@external
func test_is_variable_in_memory_returns_false_if_var_not_in_non_empty_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=77, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, FALSE);

    return ();
}

@external
func test_is_variable_in_memory_returns_false_on_empty_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local memory: felt*) = alloc();
    let memory_len = 0;

    let actual_is_var_in_memory = Memory.is_variable_in_memory(
        _selector=3, _memory_len=memory_len, _memory=memory
    );

    assert_eq(actual_is_var_in_memory, FALSE);

    return ();
}

@external
func test_get_index_of_var_in_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (actual_var_start, actual_var_end) = Memory.get_index_of_var_in_memory(
        _selector=var0.selector, _i=0, _memory=memory
    );

    assert_eq(actual_var_start, 0);
    assert_eq(actual_var_end, 9);

    let (actual_var_start, actual_var_end) = Memory.get_index_of_var_in_memory(
        _selector=var1.selector, _i=0, _memory=memory
    );

    assert_eq(actual_var_start, 9);
    assert_eq(actual_var_end, 14);

    let (actual_var_start, actual_var_end) = Memory.get_index_of_var_in_memory(
        _selector=var2.selector, _i=0, _memory=memory
    );

    assert_eq(actual_var_start, 14);
    assert_eq(actual_var_end, 21);

    let (actual_var_start, actual_var_end) = Memory.get_index_of_var_in_memory(
        _selector=var3.selector, _i=0, _memory=memory
    );

    assert_eq(actual_var_start, 21);
    assert_eq(actual_var_end, 27);

    return ();
}

@external
func test_split_memory_split_at_first_variable{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (l_len, l, v_len, v, r_len, r) = Memory._split_memory(3, memory_len, memory);

    assert_eq(l_len, 0);
    assert_eq(r_len, 3 * Variable.SIZE + var1.data_len + var2.data_len + var3.data_len);
    assert_eq(v_len, Variable.SIZE + var0.data_len);
    assert_eq(v[Variable.selector], var0.selector);
    assert_eq(v[Variable.protected], var0.protected);
    assert_eq(v[Variable.type], var0.type);
    assert_eq(v[Variable.data_len], var0.data_len);

    return ();
}

@external
func test_split_memory_split_at_last_variable{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (l_len, l, v_len, v, r_len, r) = Memory._split_memory(var3.selector, memory_len, memory);

    assert_eq(l_len, 3 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len);
    assert_eq(r_len, 0);
    assert_eq(v_len, Variable.SIZE + var3.data_len);
    assert_eq(v[Variable.selector], var3.selector);
    assert_eq(v[Variable.protected], var3.protected);
    assert_eq(v[Variable.type], var3.type);
    assert_eq(v[Variable.data_len], var3.data_len);

    return ();
}

@external
func test_split_memory_split_at_a_middle_variable{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (l_len, l, v_len, v, r_len, r) = Memory._split_memory(var2.selector, memory_len, memory);

    assert_eq(l_len, 2 * Variable.SIZE + var0.data_len + var1.data_len);
    assert_eq(r_len, Variable.SIZE + var3.data_len);
    assert_eq(v_len, Variable.SIZE + var2.data_len);
    assert_eq(v[Variable.selector], var2.selector);
    assert_eq(v[Variable.protected], var2.protected);
    assert_eq(v[Variable.type], var2.type);
    assert_eq(v[Variable.data_len], var2.data_len);

    return ();
}

@external
func test_load_variable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (var_len, var) = Memory.load_variable(var0.selector, memory_len, memory);

    assert_eq(var_len, Variable.SIZE + var0.data_len);
    assert_eq(var[Variable.selector], var0.selector);
    assert_eq(var[Variable.protected], var0.protected);
    assert_eq(var[Variable.type], var0.type);
    assert_eq(var[Variable.data_len], var0.data_len);
    assert_eq(var[Variable.SIZE + 0], 4);
    assert_eq(var[Variable.SIZE + 1], 3);
    assert_eq(var[Variable.SIZE + 2], 2);
    assert_eq(var[Variable.SIZE + 3], 1);
    assert_eq(var[Variable.SIZE + 4], 0);

    let (var_len, var) = Memory.load_variable(var1.selector, memory_len, memory);

    assert_eq(var_len, Variable.SIZE + var1.data_len);
    assert_eq(var[Variable.selector], var1.selector);
    assert_eq(var[Variable.protected], var1.protected);
    assert_eq(var[Variable.type], var1.type);
    assert_eq(var[Variable.data_len], var1.data_len);
    assert_eq(var[Variable.SIZE + 0], TRUE);

    let (var_len, var) = Memory.load_variable(var2.selector, memory_len, memory);

    assert_eq(var_len, Variable.SIZE + var2.data_len);
    assert_eq(var[Variable.selector], var2.selector);
    assert_eq(var[Variable.protected], var2.protected);
    assert_eq(var[Variable.type], var2.type);
    assert_eq(var[Variable.data_len], var2.data_len);
    assert_eq(var[Variable.SIZE + 0], TRUE);
    assert_eq(var[Variable.SIZE + 1], FALSE);
    assert_eq(var[Variable.SIZE + 2], TRUE);

    let (var_len, var) = Memory.load_variable(var3.selector, memory_len, memory);

    assert_eq(var_len, Variable.SIZE + var3.data_len);
    assert_eq(var[Variable.selector], var3.selector);
    assert_eq(var[Variable.protected], var3.protected);
    assert_eq(var[Variable.type], var3.type);
    assert_eq(var[Variable.data_len], var3.data_len);
    assert_eq(var[Variable.SIZE + 0], TRUE);
    assert_eq(var[Variable.SIZE + 1], FALSE);

    return ();
}

@external
func test_load_variable_payload{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=1,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    let (var_len, var) = Memory.load_variable_payload(var0.selector, 0, memory_len, memory);

    assert_eq(var_len, var0.data_len + 1);
    assert_eq(var[0], var0.data_len);
    assert_eq(var[1], 4);
    assert_eq(var[2], 3);
    assert_eq(var[3], 2);
    assert_eq(var[4], 1);
    assert_eq(var[5], 0);

    let (var_len, var) = Memory.load_variable_payload(var1.selector, 0, memory_len, memory);

    assert_eq(var_len, var1.data_len + 1);
    assert_eq(var[0], var1.data_len);
    assert_eq(var[1], TRUE);

    let (var_len, var) = Memory.load_variable_payload(var2.selector, 0, memory_len, memory);

    assert_eq(var_len, var2.data_len + 1);
    assert_eq(var[0], var2.data_len);
    assert_eq(var[1], TRUE);
    assert_eq(var[2], FALSE);
    assert_eq(var[3], TRUE);

    let (var_len, var) = Memory.load_variable_payload(var3.selector, 0, memory_len, memory);

    assert_eq(var_len, var3.data_len + 1);
    assert_eq(var[0], var3.data_len);
    assert_eq(var[1], TRUE);
    assert_eq(var[2], FALSE);

    return ();
}

@external
func test_update_variable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=0,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    tempvar new_var_data = new (1);
    let new_var_data_len = 1;

    let (new_memory_len, new_memory) = Memory.update_variable(
        var0.selector, memory_len, memory, new_var_data_len, new_var_data
    );
    assert_eq(new_memory_len, 23);

    let (var_len, var) = Memory.load_variable(var0.selector, new_memory_len, new_memory);

    assert_eq(var_len, Variable.SIZE + new_var_data_len);
    assert_eq(var[Variable.selector], var0.selector);
    assert_eq(var[Variable.protected], var0.protected);
    assert_eq(var[Variable.type], var0.type);
    assert_eq(var[Variable.data_len], new_var_data_len);
    assert_eq(var[Variable.SIZE + 0], new_var_data[0]);

    let (new_memory_len, new_memory) = Memory.update_variable(
        var1.selector, memory_len, memory, new_var_data_len, new_var_data
    );
    assert_eq(new_memory_len, 27);

    let (var_len, var) = Memory.load_variable(var1.selector, new_memory_len, new_memory);

    assert_eq(var_len, Variable.SIZE + new_var_data_len);
    assert_eq(var[Variable.selector], var1.selector);
    assert_eq(var[Variable.protected], var1.protected);
    assert_eq(var[Variable.type], var1.type);
    assert_eq(var[Variable.data_len], new_var_data_len);
    assert_eq(var[Variable.SIZE + 0], new_var_data[0]);

    let (new_memory_len, new_memory) = Memory.update_variable(
        var3.selector, memory_len, memory, new_var_data_len, new_var_data
    );
    assert_eq(new_memory_len, 26);

    let (var_len, var) = Memory.load_variable(var3.selector, new_memory_len, new_memory);

    assert_eq(var_len, Variable.SIZE + new_var_data_len);
    assert_eq(var[Variable.selector], var3.selector);
    assert_eq(var[Variable.protected], var3.protected);
    assert_eq(var[Variable.type], var3.type);
    assert_eq(var[Variable.data_len], new_var_data_len);
    assert_eq(var[Variable.SIZE + 0], new_var_data[0]);

    return ();
}

@external
func test_update_variable_reverts_if_consts_are_updated{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector=3,
        protected=FALSE,
        type=DataTypes.FELT,
        data_len=5,
        );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector=6,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=1,
        );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector=2,
        protected=TRUE,
        type=DataTypes.BOOL,
        data_len=3,
        );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    tempvar var3 = new Variable(
        selector=7,
        protected=FALSE,
        type=DataTypes.BOOL,
        data_len=2,
        );
    tempvar var3_data = new (TRUE, FALSE);

    let (local memory: felt*) = alloc();
    let memory_len = 4 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len + var3.data_len;

    // Copy first variable
    memcpy(memory, var0, Variable.SIZE);
    memcpy(memory + Variable.SIZE, var0_data, var0.data_len);

    // Copy second variable
    let offset = Variable.SIZE + var0.data_len;
    memcpy(memory + offset, var1, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var1_data, var1.data_len);

    // Copy third variable
    let offset = offset + Variable.SIZE + var1.data_len;
    memcpy(memory + offset, var2, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var2_data, var2.data_len);

    // Copy fourth variable
    let offset = offset + Variable.SIZE + var2.data_len;
    memcpy(memory + offset, var3, Variable.SIZE);
    memcpy(memory + offset + Variable.SIZE, var3_data, var3.data_len);

    tempvar new_var_data = new (1);
    let new_var_data_len = 1;

    %{ expect_revert(error_message="CONSTS ARE IMMUTABLE") %}
    let (new_memory_len, new_memory) = Memory.update_variable(
        var2.selector, memory_len, memory, new_var_data_len, new_var_data
    );

    return ();
}
