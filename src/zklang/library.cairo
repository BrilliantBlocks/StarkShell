%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.constants import API


struct Primitive {
    class_hash: felt,
    selector: felt,
}

struct Variable {
    selector: felt,
    protected: felt,
    type: felt,
    data_len:felt,
}

struct Instruction {
    primitive: Primitive,
    input: Variable,
    output: Variable,
}

struct DataTypes {
    FELT: felt,
    BOOL: felt,
}

namespace Program {

}

namespace Memory {
    func init{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_calldata_len: felt, _calldata: felt*) -> (memory_len: felt, memory: felt*) {
        alloc_locals;
        let (local memory: felt*) = alloc();
        let memory_len = Variable.SIZE + _calldata_len;
        tempvar var_metadata = new Variable(
            selector = API.CORE.__ZKLANG__CALLDATA_VAR,
            protected = FALSE,
            type = DataTypes.FELT,
            data_len = _calldata_len,
        );
        memcpy(memory, var_metadata, Variable.SIZE);
        memcpy(memory + Variable.SIZE, _calldata, _calldata_len);
        return (memory_len, memory);
    }
}
