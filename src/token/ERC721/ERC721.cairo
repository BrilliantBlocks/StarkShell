%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import get_caller_address, library_call

from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.registers import get_label_location
from src.token.ERC721.util.ShortString import uint256_to_ss
from src.token.ERC721.util.Safemath import SafeUint256

from src.constants import FUNCTION_SELECTORS, IERC721_RECEIVER_ID, IACCOUNT_ID, IERC721_ID
from src.token.ERC721.IERC721_Receiver import IERC721_Receiver
from src.ERC165.IERC165 import IERC165

//
// Events
//

@event
func Approval(_owner: felt, _approved: felt, _tokenId: Uint256) {
}

@event
func ApprovalForAll(_owner: felt, _operator: felt, _approved: felt) {
}

@event
func Transfer(_from: felt, _to: felt, _tokenId: Uint256) {
}

//
// Storage
//

@storage_var
func contract_name() -> (res: felt) {
}

@storage_var
func contract_symbol() -> (res: felt) {
}

@storage_var
func owners(_tokenId: Uint256) -> (res: felt) {
}

@storage_var
func balances(_owner: felt) -> (res: Uint256) {
}

@storage_var
func token_approvals(_tokenId: Uint256) -> (res: felt) {
}

@storage_var
func operator_approvals(_owner: felt, _operator: felt) -> (res: felt) {
}

@storage_var
func base_token_uri(index: felt) -> (res: felt) {
}

@storage_var
func base_token_uri_len() -> (res: felt) {
}

//
// View
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (_name: felt) {
    let (name) = contract_name.read();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (_symbol: felt) {
    let (symbol) = contract_symbol.read();
    return (symbol,);
}

@view
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_owner: felt) -> (
    res: Uint256
) {
    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(_owner);
    }
    let (res) = balances.read(_owner);
    return (res,);
}

@view
func ownerOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    with_attr error_message("Token ID is not a valid Uint256.") {
        uint256_check(_tokenId);
    }
    let (owner) = owners.read(_tokenId);
    with_attr error_message("The token ID is not existent.") {
        assert_not_zero(owner);
    }
    return (owner,);
}

@view
func getApproved{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    with_attr error_message("Token ID is not a valid Uint256.") {
        uint256_check(_tokenId);
    }
    let (exists) = _exists(_tokenId);
    with_attr error_message("Token is nonexistent.") {
        assert exists = TRUE;
    }
    let (approved) = token_approvals.read(_tokenId);
    return (approved,);
}

@view
func isApprovedForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _owner: felt, _operator: felt
) -> (res: felt) {
    let (is_approved) = operator_approvals.read(_owner, _operator);
    return (is_approved,);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len: felt, tokenURI: felt*) = _long_tokenURI(_tokenId);
    return (tokenURI_len, tokenURI);
}

//
// Externals
//

@external
func initFacet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _name: felt, _symbol: felt, tokenURI_len: felt, tokenURI: felt*
) -> () {
    contract_name.write(_name);
    contract_symbol.write(_symbol);
    _setBaseTokenURI(tokenURI_len, tokenURI);
    return ();
}

@external
func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _tokenId: Uint256
) -> () {
    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(_to);
    }

    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }

    // TODO necessary? induces conflict with diamond init
    //     with_attr error_message("Cannot mint token id 0"):
    //         assert_uint256_is_not_zero(_tokenId)
    //     end

    let (exists) = _exists(_tokenId);
    with_attr error_message("Token already minted.") {
        assert exists = FALSE;
    }

    let (balance) = balances.read(_to);
    let (new_balance) = SafeUint256.add(balance, Uint256(1, 0));
    balances.write(_to, new_balance);
    owners.write(_tokenId, _to);
    Transfer.emit(0, _to, _tokenId);
    return ();
}

@external
func _safeMint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> () {
    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }
    _mint(_to, _tokenId);

    let (success) = _check_onERC721Received(0, _to, _tokenId, data_len, data);

    with_attr error_message("Transfer to non ERC721Receiver implementer.") {
        assert_not_zero(success);
    }
    return ();
}

@external
func _burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_tokenId: Uint256) -> (
    ) {
    alloc_locals;

    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }
    let (owner) = ownerOf(_tokenId);

    _approve(0, _tokenId);

    let (balance) = balances.read(owner);
    let (new_balance) = SafeUint256.sub_le(balance, Uint256(1, 0));
    balances.write(owner, new_balance);

    owners.write(_tokenId, 0);
    Transfer.emit(owner, 0, _tokenId);
    return ();
}

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _tokenId: Uint256
) -> () {
    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }

    let (caller) = get_caller_address();

    let (owner) = owners.read(_tokenId);
    with_attr error_message("You cannot set approval to current owner.") {
        assert_not_equal(owner, _to);
    }

    if (caller == owner) {
        _approve(_to, _tokenId);
        return ();
    } else {
        let (is_approved) = operator_approvals.read(owner, caller);
        with_attr error_message("Caller is neither owner nor approved for all") {
            assert_not_zero(is_approved);
        }
        _approve(_to, _tokenId);
        return ();
    }
}

@external
func setApprovalForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _operator: felt, _approved: felt
) -> () {
    let (caller) = get_caller_address();
    with_attr error_message("Either the caller or operator is the zero address") {
        assert_not_zero(caller * _operator);
    }
    with_attr error_message("You cannot set approval for yourself.") {
        assert_not_equal(caller, _operator);
    }

    with_attr error_message("Approval parameter is not a boolean.") {
        assert _approved * (1 - _approved) = 0;
    }

    operator_approvals.write(caller, _operator, _approved);
    ApprovalForAll.emit(caller, _operator, _approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256
) -> () {
    alloc_locals;
    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }
    let (caller) = get_caller_address();
    let (is_approved) = _is_approved_or_owner(caller, _tokenId);
    with_attr error_message("Either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }

    _transfer(_from, _to, _tokenId);

    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> () {
    alloc_locals;
    with_attr error_message("Token ID is not valid.") {
        uint256_check(_tokenId);
    }
    let (caller) = get_caller_address();
    let (is_approved) = _is_approved_or_owner(caller, _tokenId);
    with_attr error_message("Either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }

    _safe_transfer(_from, _to, _tokenId, data_len, data);
    return ();
}

//
// Internals
//

func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    let (res) = owners.read(_tokenId);

    if (res == 0) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
}

func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256
) -> () {
    let (owner) = ownerOf(_tokenId);
    with_attr error_message("Transfer from incorrect owner") {
        assert owner = _from;
    }

    with_attr error_message("Cannot transfer to the zero address") {
        assert_not_zero(_to);
    }

    // Clear approvals
    _approve(0, _tokenId);

    // Decrease owner balance
    let (owner_balance) = balances.read(_from);
    let (new_balance: Uint256) = SafeUint256.sub_le(owner_balance, Uint256(1, 0));
    balances.write(_from, new_balance);

    // Increase receiver balance
    let (receiver_balance) = balances.read(_to);
    let (new_balance: Uint256) = SafeUint256.add(receiver_balance, Uint256(1, 0));
    balances.write(_to, new_balance);

    // Update token_id owner
    owners.write(_tokenId, _to);
    Transfer.emit(_from, _to, _tokenId);
    return ();
}

func _safe_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> () {
    _transfer(_from, _to, _tokenId);

    let (success) = _check_onERC721Received(_from, _to, _tokenId, data_len, data);

    with_attr error_message("Transfer to non ERC721Receiver implementer.") {
        assert_not_zero(success);
    }
    return ();
}

func _check_onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> (success: felt) {
    let (caller) = get_caller_address();
    let (is_supported) = IERC165.supportsInterface(_to, IERC721_RECEIVER_ID);
    if (is_supported == TRUE) {
        let (selector) = IERC721_Receiver.onERC721Received(
            _to, caller, _from, _tokenId, data_len, data
        );
        with_attr error_message("Transfer to non ERC721Receiver implementer") {
            assert selector = IERC721_RECEIVER_ID;
        }
        return (TRUE,);
    }

    let (is_account) = IERC165.supportsInterface(_to, IACCOUNT_ID);
    return (is_account,);
}

func _approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to: felt, _tokenId: Uint256
) -> () {
    token_approvals.write(_tokenId, _to);
    let (owner) = ownerOf(_tokenId);
    Approval.emit(owner, _to, _tokenId);
    return ();
}

func _is_approved_or_owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    spender: felt, _tokenId: Uint256
) -> (res: felt) {
    alloc_locals;

    let (exists) = _exists(_tokenId);
    with_attr error_message("Token is nonexistent.") {
        assert exists = TRUE;
    }

    let (owner) = ownerOf(_tokenId);
    if (owner == spender) {
        return (TRUE,);
    }

    let (approved_address) = getApproved(_tokenId);
    if (approved_address == spender) {
        return (TRUE,);
    }

    let (is_operator) = isApprovedForAll(owner, spender);
    if (is_operator == TRUE) {
        return (TRUE,);
    }

    return (FALSE,);
}

func _long_tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;

    let (exists) = _exists(_tokenId);
    with_attr error_message("Token is nonexistent.") {
        assert exists = TRUE;
    }

    // Return tokenURI with an array of felts, `${base_token_uri}/${token_id}`
    let (local base_tokenURI) = alloc();
    let (local base_tokenURI_len) = base_token_uri_len.read();
    _baseTokenURI(base_tokenURI_len, base_tokenURI);
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(_tokenId);
    let (tokenURI_len, tokenURI) = concat_arr(
        base_tokenURI_len, base_tokenURI, token_id_ss_len, token_id_ss
    );
    return (tokenURI_len, tokenURI);
}

func _baseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_tokenURI_len: felt, base_tokenURI: felt*
) -> () {
    if (base_tokenURI_len == 0) {
        return ();
    }
    let (base) = base_token_uri.read(base_tokenURI_len);
    assert [base_tokenURI] = base;
    _baseTokenURI(base_tokenURI_len=base_tokenURI_len - 1, base_tokenURI=base_tokenURI + 1);
    return ();
}

func _setBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI_len: felt, tokenURI: felt*
) -> () {
    _populateBaseTokenURI(tokenURI_len, tokenURI);
    base_token_uri_len.write(tokenURI_len);
    return ();
}

func _populateBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI_len: felt, tokenURI: felt*
) -> () {
    if (tokenURI_len == 0) {
        return ();
    }
    base_token_uri.write(index=tokenURI_len, value=[tokenURI]);
    _populateBaseTokenURI(tokenURI_len=tokenURI_len - 1, tokenURI=tokenURI + 1);
    return ();
}

@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    return ();
}

@view
func __get_function_selectors__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ) -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=8, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC721.ownerOf;
    dw FUNCTION_SELECTORS.ERC721.balanceOf;
    dw FUNCTION_SELECTORS.ERC721.safeTransferFrom;
    dw FUNCTION_SELECTORS.ERC721.transferFrom;
    dw FUNCTION_SELECTORS.ERC721.approve;
    dw FUNCTION_SELECTORS.ERC721.setApprovalForAll;
    dw FUNCTION_SELECTORS.ERC721.getApproved;
    dw FUNCTION_SELECTORS.ERC721.isApprovedForAll;
}

// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC721_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}

func concat_arr{range_check_ptr}(arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*) -> (
    res_len: felt, res: felt*
) {
    alloc_locals;
    let (local res: felt*) = alloc();
    memcpy(res, arr1, arr1_len);
    memcpy(res + arr1_len, arr2, arr2_len);
    return (arr1_len + arr2_len, res);
}
