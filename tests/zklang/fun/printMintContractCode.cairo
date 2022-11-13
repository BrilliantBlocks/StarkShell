%builtins output
from starkware.cairo.common.serialize import serialize_word

from tests.zklang.fun.mintContract import mintContract

func main{output_ptr: felt*}() {
    let (felt_code_len, felt_code) = mintContract(
        _diamond_hash=1763777335473612205539358602510685953121960447656504481387766669807480154069,
        _erc721_hash=1312078427945816366278672907551550189477102645763819624254806928979747049136,
    );
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
