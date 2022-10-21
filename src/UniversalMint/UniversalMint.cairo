%lang starknet
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_contract_address, library_call


from src.constants import FUNCTION_SELECTORS
from src.ERC2535.IDiamond import IDiamond
from src.UniversalMint.library import UniversalMint


@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _calldata_len: felt, _calldata: felt*
    ) -> () {
    let (self) = get_contract_address();
    let (token_facet_class_hash) = IDiamond.getImplementation(self);
    with_attr error_message("TOKEN FACET NOT FOUND") {
        assert_not_zero(token_facet_class_hash);
    }
    library_call(
        class_hash=token_facet_class_hash,
        function_selector=FUNCTION_SELECTORS.UNIVERSAL_MINT.mint,
        calldata_size=_calldata_len,
        calldata=_calldata,
    );
    return ();
}

@external
func mintBach{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _calldata_len: felt, _calldata: felt*
    ) -> () {
    let (self) = get_contract_address();
    let (token_facet_class_hash) = IDiamond.getImplementation(self);
    with_attr error_message("TOKEN FACET NOT FOUND") {
        assert_not_zero(token_facet_class_hash);
    }
    library_call(
        class_hash=token_facet_class_hash,
        function_selector=FUNCTION_SELECTORS.UNIVERSAL_MINT.mint,
        calldata_size=_calldata_len,
        calldata=_calldata,
    );
    return ();
}

// ===================
// Mandatory functions
// ===================

/// @dev Initialize this facet
@external
func __constructor__() -> () {
    return ();
}

/// @dev Remove this facet
@external
func __destructor__() -> () {
    return ();
}

/// @dev Exported view and invokable functions of this facet
@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=2, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.UNIVERSAL_MINT.mint;
    dw FUNCTION_SELECTORS.UNIVERSAL_MINT.mintBatch;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
