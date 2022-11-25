struct Primitive {
    class_hash: felt,
    selector: felt,
}

struct Function {
    selector: felt,
    program_hash: felt,
    repo_address: felt,
    // group: felt,
}

struct Variable {
    selector: felt,
    protected: felt,
    type: felt,
    data_len: felt,
    // owner: felt, // fun or group
}

struct Instruction {
    primitive: Primitive,
    input1: Variable,
    input2: Variable,
    output: Variable,
}

struct DataTypes {
    FELT: felt,
    BOOL: felt,
}
