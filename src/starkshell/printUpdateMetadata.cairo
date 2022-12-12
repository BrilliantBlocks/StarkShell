%builtins output
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

from src.starkshell.updateMetadata import updateMetadata

func main{output_ptr: felt*}() {
    alloc_locals;

    let (felt_code_len, felt_code) = updateMetadata();
    print(felt_code_len, felt_code);

    return ();
}

func print{output_ptr: felt*}(felt_code_len: felt, felt_code: felt*) {
    if (felt_code_len == 0) {
        return ();
    }

    serialize_word(felt_code[0]);

    return print(felt_code_len - 1, felt_code + 1);
}
