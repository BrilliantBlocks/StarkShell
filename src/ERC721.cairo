%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
        assert_not_equal,
        assert_not_zero,
    )
from starkware.starknet.common.syscalls import (
        get_caller_address,
        library_call,
    )

from starkware.cairo.common.uint256 import Uint256, uint256_check
from contracts.lib.Assertions import assert_uint256_is_not_zero, felt_is_boolean, assert_only_diamond
from contracts.lib.Safemath import SafeUint256
from contracts.lib.ShortString import uint256_to_ss

from contracts.facets.token.ERC721.IERC721_Receiver import IERC721_Receiver
from contracts.facets.diamond.IERC165 import IERC165
from contracts.lib.Constants import IERC721_RECEIVER_ID, IACCOUNT_ID

from contracts.lib.Array import concat_arr

#
# Events
#

@event
func Approval(_owner: felt, _approved: felt, _tokenId: Uint256):
end

@event
func ApprovalForAll(_owner: felt, _operator: felt, _approved: felt):
end

@event
func Transfer(_from: felt, _to: felt, _tokenId: Uint256):
end

#
# Storage
#

@storage_var
func contract_name() -> (res: felt):
end

@storage_var
func contract_symbol() -> (res: felt):
end

@storage_var
func owners(_tokenId : Uint256) -> (res : felt):
end

@storage_var
func balances(_owner : felt) -> (res : Uint256):
end

@storage_var
func token_approvals(_tokenId : Uint256) -> (res : felt):
end

@storage_var
func operator_approvals(_owner: felt, _operator: felt) -> (res: felt):
end

@storage_var
func base_token_uri(index: felt) -> (res: felt):
end

@storage_var
func base_token_uri_len() -> (res: felt):
end


#
# View
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }() -> (_name: felt):

    let (name) = contract_name.read()
    return (name)
end


@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }() -> (_symbol: felt):

    let (symbol) = contract_symbol.read()
    return (symbol)
end


@view
func balanceOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_owner : felt) -> (res : Uint256):

    with_attr error_message("Address cannot be zero."):
        assert_not_zero(_owner)
    end
    let (res) = balances.read(_owner)
    return (res)
end


@view
func ownerOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_tokenId : Uint256) -> (res : felt):

    with_attr error_message("Token ID is not a valid Uint256."):
        uint256_check(_tokenId)
    end
    let (owner) = owners.read(_tokenId)
    with_attr error_message("The token ID is not existent."):
        assert_not_zero(owner)
    end
    return (owner)
end


@view
func getApproved{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_tokenId : Uint256) -> (res : felt):

    with_attr error_message("Token ID is not a valid Uint256."):
        uint256_check(_tokenId)
    end
    let (exists) = _exists(_tokenId)
    with_attr error_message("Token is nonexistent."):
        assert exists = TRUE
    end
    let (approved) = token_approvals.read(_tokenId)
    return (approved)
end


@view
func isApprovedForAll{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_owner : felt, _operator : felt) -> (res : felt):

    let (is_approved) = operator_approvals.read(_owner, _operator)
    return (is_approved)
end


@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):

    let (tokenURI_len: felt, tokenURI: felt*) = _long_tokenURI(_tokenId)
    return (tokenURI_len, tokenURI)
end

#
# Externals
#

@external
func initFacet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _name: felt,
        _symbol: felt,
        tokenURI_len: felt,
        tokenURI: felt*,
    ) -> ():

    contract_name.write(_name)
    contract_symbol.write(_symbol)
    _setBaseTokenURI(tokenURI_len, tokenURI)
    return ()
end


@external
func _mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_to : felt, _tokenId : Uint256) -> ():
    
    assert_only_diamond()

    with_attr error_message("Address cannot be zero."):
        assert_not_zero(_to)
    end

    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end

    with_attr error_message("Cannot mint token id 0"):
        assert_uint256_is_not_zero(_tokenId)
    end

    let (exists) = _exists(_tokenId)
    with_attr error_message("Token already minted."):
        assert exists = FALSE
    end

    let (balance) = balances.read(_to)
    let (new_balance) = SafeUint256.add(balance, Uint256(1, 0))
    balances.write(_to, new_balance)
    owners.write(_tokenId, _to)
    Transfer.emit(0, _to, _tokenId)
    return ()
end


@external
func _safeMint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
    }(_to: felt, _tokenId: Uint256, data_len: felt, data: felt*) -> ():

    assert_only_diamond()

    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end
    _mint(_to, _tokenId)

    let (success) = _check_onERC721Received(0, _to, _tokenId, data_len, data)
    
    with_attr error_message("Transfer to non ERC721Receiver implementer."):
        assert_not_zero(success)
    end
    return ()
end


@external
func _burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_tokenId : Uint256) -> ():
    
    alloc_locals

    assert_only_diamond()

    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end
    let (owner) = ownerOf(_tokenId)

    _approve(0, _tokenId)

    let (balance) = balances.read(owner)
    let (new_balance) = SafeUint256.sub_le(balance, Uint256(1, 0))
    balances.write(owner, new_balance)

    owners.write(_tokenId, 0)
    Transfer.emit(owner, 0, _tokenId)
    return ()
end


@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_to : felt, _tokenId : Uint256) -> ():
    
    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end

    let (caller) = get_caller_address()

    let (owner) = owners.read(_tokenId)
    with_attr error_message("You cannot set approval to current owner."):
        assert_not_equal(owner, _to)
    end

    if caller == owner:
        _approve(_to, _tokenId)
        return ()
    else:
        let (is_approved) = operator_approvals.read(owner, caller)
        with_attr error_message("Caller is neither owner nor approved for all"):
            assert_not_zero(is_approved)
        end
        _approve(_to, _tokenId)
        return ()
    end
end


@external
func setApprovalForAll{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_operator : felt, _approved : felt) -> ():

    let (caller) = get_caller_address()
    with_attr error_message("Either the caller or operator is the zero address"):
        assert_not_zero(caller * _operator)
    end
    with_attr error_message("You cannot set approval for yourself."):
        assert_not_equal(caller, _operator)
    end

    let (is_boolean) = felt_is_boolean(_approved)
    with_attr error_message("Approval parameter is not a boolean."):
        assert is_boolean = TRUE
    end

    operator_approvals.write(caller, _operator, _approved)
    ApprovalForAll.emit(caller, _operator, _approved)
    return ()
end


@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_from : felt, _to : felt, _tokenId : Uint256) -> ():
    
    alloc_locals
    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end
    let (caller) = get_caller_address()
    let (is_approved) = _is_approved_or_owner(caller, _tokenId)
    with_attr error_message("Either is not approved or the caller is the zero address"):
        assert_not_zero(caller * is_approved)
    end

    _transfer(_from, _to, _tokenId)

    return ()
end


@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr
    }(_from : felt, _to : felt, _tokenId : Uint256, data_len : felt, data : felt*) -> ():
    
    alloc_locals
    with_attr error_message("Token ID is not valid."):
        uint256_check(_tokenId)
    end
    let (caller) = get_caller_address()
    let (is_approved) = _is_approved_or_owner(caller, _tokenId)
    with_attr error_message("Either is not approved or the caller is the zero address"):
        assert_not_zero(caller * is_approved)
    end

    _safe_transfer(_from, _to, _tokenId, data_len, data)
    return ()
end


#
# Internals
#

func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_tokenId : Uint256) -> (res : felt):
    
    let (res) = owners.read(_tokenId)

    if res == 0:
        return (FALSE)
    else:
        return (TRUE)
    end
end


func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_from : felt, _to : felt, _tokenId : Uint256) -> ():
    
    let (owner) = ownerOf(_tokenId)
    with_attr error_message("Transfer from incorrect owner"):
        assert owner = _from
    end

    with_attr error_message("Cannot transfer to the zero address"):
        assert_not_zero(_to)
    end

    # Clear approvals
    _approve(0, _tokenId)

    # Decrease owner balance
    let (owner_balance) = balances.read(_from)
    let (new_balance: Uint256) = SafeUint256.sub_le(owner_balance, Uint256(1, 0))
    balances.write(_from, new_balance)

    # Increase receiver balance
    let (receiver_balance) = balances.read(_to)
    let (new_balance: Uint256) = SafeUint256.add(receiver_balance, Uint256(1, 0))
    balances.write(_to, new_balance)

    # Update token_id owner
    owners.write(_tokenId, _to)
    Transfer.emit(_from, _to, _tokenId)
    return ()
end


func _safe_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*) -> ():
    
    _transfer(_from, _to, _tokenId)

    let (success) = _check_onERC721Received(_from, _to, _tokenId, data_len, data)

    with_attr error_message("Transfer to non ERC721Receiver implementer."):
        assert_not_zero(success)
    end
    return ()
end


func _check_onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*) -> (success: felt):
    
    let (caller) = get_caller_address()
    let (is_supported) = IERC165.supportsInterface(_to, IERC721_RECEIVER_ID)
    if is_supported == TRUE:
        let (selector) = IERC721_Receiver.onERC721Received(
            _to, caller, _from, _tokenId, data_len, data
        )
        with_attr error_message("Transfer to non ERC721Receiver implementer"):
            assert selector = IERC721_RECEIVER_ID
        end
        return (TRUE)
    end

    let (is_account) = IERC165.supportsInterface(_to, IACCOUNT_ID)
    return (is_account)
end


func _approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_to : felt, _tokenId : Uint256) -> ():
    
    token_approvals.write(_tokenId, _to)
    let (owner) = ownerOf(_tokenId)
    Approval.emit(owner, _to, _tokenId)
    return ()
end


func _is_approved_or_owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
    }(spender: felt, _tokenId: Uint256) -> (res: felt):

    alloc_locals

    let (exists) = _exists(_tokenId)
    with_attr error_message("Token is nonexistent."):
        assert exists = TRUE
    end

    let (owner) = ownerOf(_tokenId)
    if owner == spender:
        return (TRUE)
    end

    let (approved_address) = getApproved(_tokenId)
    if approved_address == spender:
        return (TRUE)
    end

    let (is_operator) = isApprovedForAll(owner, spender)
    if is_operator == TRUE:
        return (TRUE)
    end

    return (FALSE)
end


func _long_tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):

    alloc_locals

    let (exists) = _exists(_tokenId)
    with_attr error_message("Token is nonexistent."):
        assert exists = TRUE
    end

    # Return tokenURI with an array of felts, `${base_token_uri}/${token_id}`
    let (local base_tokenURI) = alloc()
    let (local base_tokenURI_len) = base_token_uri_len.read()
    _baseTokenURI(base_tokenURI_len, base_tokenURI)
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(_tokenId)
    let (tokenURI, tokenURI_len) = concat_arr(
        base_tokenURI_len, base_tokenURI, token_id_ss_len, token_id_ss,
    )
    return (tokenURI_len, tokenURI)
end


func _baseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(base_tokenURI_len: felt, base_tokenURI: felt*) -> ():

    if base_tokenURI_len == 0:
        return ()
    end
    let (base) = base_token_uri.read(base_tokenURI_len)
    assert [base_tokenURI] = base
    _baseTokenURI(base_tokenURI_len=base_tokenURI_len - 1, base_tokenURI=base_tokenURI + 1)
    return ()
end


func _setBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*) -> ():

    _populateBaseTokenURI(tokenURI_len, tokenURI)
    base_token_uri_len.write(tokenURI_len)
    return ()
end


func _populateBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*) -> ():

    if tokenURI_len == 0:
        return ()
    end
    base_token_uri.write(index=tokenURI_len, value=[tokenURI])
    _populateBaseTokenURI(tokenURI_len=tokenURI_len - 1, tokenURI=tokenURI + 1)
    return ()
end
