%builtins output
from starkware.cairo.common.serialize import serialize_word

from src.starkshell.mul import mul

func main{output_ptr: felt*}() {
    // Replace with required function
    let (felt_code_len, felt_code) = mul(4, 3);
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
