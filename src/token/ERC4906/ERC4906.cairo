%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_sub, uint256_eq, uint256_add
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import split_felt, assert_not_zero

from src.constants import FUNCTION_SELECTORS, IERC4906_ID


@event
func MetadataUpdate(token_id: Uint256) {
}

@event
func BatchMetadataUpdate(from_token_id: Uint256, to_token_id: Uint256) {
}


@storage_var
func _token_uri(token_id: Uint256) -> (token_uri: felt) {
}


@external
func updateTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, token_uri: felt
) -> () {
    
    with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }
    
    with_attr error_message("Token URI must not be zero") {
        assert_not_zero(token_uri);
    }

    let (exists) = _exists(token_id);
    with_attr error_message("Token is nonexistent") {
        assert exists = TRUE;
    }

    _token_uri.write(token_id, token_uri);
    MetadataUpdate.emit(token_id);
    return ();
}


@external
func updateTokenBatchURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id_from: Uint256, token_id_to: Uint256, token_uri_len: felt, token_uri: felt*
) -> () {
    alloc_locals;

    let (token_range) = uint256_sub(token_id_to, token_id_from);
    let (token_uri_len_uint256) = convertFeltToUint256(token_uri_len);
    let (equals) = uint256_eq(token_range, token_uri_len_uint256);
    with_attr error_message("Number of token IDs must match number of number token URIs") {
        assert equals = TRUE;
    }

    update_token_batch_uri(token_id_from, token_id_to, token_uri_len, token_uri);
    BatchMetadataUpdate.emit(token_id_from, token_id_to);

    return ();
}


func update_token_batch_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_token_id: Uint256, token_id_to: Uint256, token_uri_len: felt, token_uri: felt*
) -> () {
    alloc_locals;

    with_attr error_message("Token from range is not a valid Uint256") {
        uint256_check(current_token_id);
    }

    with_attr error_message("Token URI from range must not be zero") {
        assert_not_zero(token_uri[0]);
    }

    let (exists) = _exists(current_token_id);
    with_attr error_message("Token from range is nonexistent") {
        assert exists = TRUE;
    }

    let (equals) = uint256_eq(current_token_id, token_id_to);
    if (equals == TRUE) {
        _token_uri.write(current_token_id, token_uri[0]);
        return ();
    }

    _token_uri.write(current_token_id, token_uri[0]);
    let (next_token_id, _) = uint256_add(current_token_id, Uint256(1,0));
    return update_token_batch_uri(next_token_id, token_id_to, token_uri_len - 1, token_uri + 1);
}


func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (bool: felt) {
    
    let (exists) = _token_uri.read(token_id);
    
    if (exists == FALSE) {
        return (FALSE,);
    }

    return (TRUE,);
}


func convertFeltToUint256{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    input: felt
) -> (output: Uint256) {
    let (output_high, output_low) = split_felt(input);
    let output = Uint256(output_low, output_high);

    return (output,);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=2, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC4906.updateTokenURI;
    dw FUNCTION_SELECTORS.ERC4906.updateTokenBatchURI;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC4906_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}