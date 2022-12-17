%builtins output pedersen range_check
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.serialize import serialize_word

from src.bootstrap.config.calldata import get_calldata
from src.bootstrap.structs import ClassHash
from src.zkode.diamond.structs import FacetCut

func main{output_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local owner;
    local root;
    local diamond;
    local diamondCut;
    local erc721;
    local feltmap;
    local flobDb;
    local metadata;
    local starkshell;
    local salt;
    local bootstrapper;
    %{
        import os

        ids.salt = int(os.getenv("SALT"))
        ids.bootstrapper = int(os.getenv("BOOTSTRAPPER_HASH"), 16)
        ids.owner = int(os.getenv("OWNER"), 16)
        ids.root = int(os.getenv("ROOT"), 16) if os.environ["ROOT"] != "" else 0
        ids.diamond = int(os.getenv("DIAMOND_HASH"), 16)
        ids.diamondCut = int(os.getenv("DIAMOND_CUT_HASH"), 16)
        ids.erc721 = int(os.getenv("ERC721_HASH"), 16)
        ids.feltmap = int(os.getenv("FELTMAP_HASH"), 16)
        ids.flobDb = int(os.getenv("FLOBDB_HASH"), 16)
        ids.metadata = int(os.getenv("METADATA_HASH"), 16)
        ids.starkshell = int(os.getenv("STARKSHELL_HASH"), 16)
    %}

    let (facetCut_len, facetCut, calldata_len, calldata) = get_calldata(
        owner, root, diamond, ClassHash(diamondCut, erc721, feltmap, flobDb, metadata, starkshell)
    );

    serialize_word(salt);
    serialize_word(diamond);
    serialize_word(bootstrapper);
    serialize_word(feltmap);
    serialize_word(facetCut_len);
    print_array(facetCut_len * FacetCut.SIZE, cast(facetCut, felt*));
    serialize_word(calldata_len);
    print_array(calldata_len, calldata);

    return ();
}

func print_array{output_ptr: felt*}(_el_len: felt, _el: felt*) {
    if (_el_len == 0) {
        return ();
    }

    serialize_word(_el[0]);

    return print_array(_el_len - 1, _el + 1);
}
