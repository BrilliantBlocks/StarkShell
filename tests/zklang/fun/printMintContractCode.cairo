%builtins output
from starkware.cairo.common.serialize import serialize_word

from tests.zklang.fun.mintContract import mintContract

func main{output_ptr: felt*}() {
    let (felt_code_len, felt_code) = mintContract(
        _diamond_hash=1447094753341282648861214365097198356233255058345978742945440393314393605907,
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
