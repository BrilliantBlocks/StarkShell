%builtins output
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

from src.starkshell.mintContract import mintContract

func main{output_ptr: felt*}() {
    alloc_locals;
    local diamond_hash;
    local erc721_hash;
    %{
        import os
        ids.diamond_hash = int(os.getenv("DIAMOND_HASH"), 16)
        ids.erc721_hash = int(os.getenv("ERC721_HASH"), 16)
    %}

    let (felt_code_len, felt_code) = mintContract(
        _diamond_hash=diamond_hash, _erc721_hash=erc721_hash
    );
    serialize_word(felt_code_len);
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
