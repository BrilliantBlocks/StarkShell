%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import split_felt, assert_not_zero
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    library_call,
)
from starkware.cairo.common.uint256 import Uint256

from src.constants import FUNCTION_SELECTORS, IDIAMONDLOUPE_ID, NULL
from src.ERC2535.IDiamondCut import SetAlias, SetFunctionFee
from src.ERC721.IERC721 import IERC721
from src.BFR.IBFR import IBFR

struct Fee {
    charger: felt,
    amount: felt,
    erc20_contract: felt,
}


/// @dev Store the address of the factory contract
// @return Address of its parent smart contract
@storage_var
func root_() -> (res: felt) {
}

/// @dev Use bitmap of facet configuration in facet flyweight
/// @return Bitmap
@storage_var
func facet_key_() -> (res: felt) {
}

/// @return Assigned selector
@storage_var
func alias_(alias_selector: felt) -> (res: felt) {
}

@storage_var
func function_fee_(chargee: felt) -> (res: Fee) {
}

/// @dev Enum
struct FacetCutAction {
    Add: felt,
    Replace: felt,
    Remove: felt,
}

namespace Diamond {
    func _facetAddresses{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }() -> (res_len: felt, res: felt*) {
        alloc_locals;
        let (key) = facet_key_.read();
        let (r) = root_.read();
        let (f_len, f) = IBFR.resolveKey(r, key);
        return (f_len, f);
    }

    func _facetAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_functionSelector: felt) -> (res: felt) {
        alloc_locals;
        let (f_len, f) = _facetAddresses();
        let (class_hash) = _facet_address(f_len, f, _functionSelector);
        Assert.selector_exists(class_hash);
        return (class_hash,);
    }

    func _facet_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _facets_len: felt, _facets: felt*, _functionSelector: felt
    ) -> (res: felt) {
        alloc_locals;
        if (_facets_len == 0) {
            return (0,);
        }
        let (selectors_len: felt, selectors: felt*) = _facetFunctionSelectors(_facets[0]);
        let (is_implemented) = _is_implemented(selectors_len, selectors, _functionSelector);
        if (is_implemented == TRUE) {
            return (_facets[0],);
        }
        return _facet_address(_facets_len - 1, _facets + 1, _functionSelector);
    }

    func _is_implemented{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selectors_len: felt, _selectors: felt*, _functionSelector: felt
    ) -> (res: felt) {
        if (_selectors_len == 0) {
            return (FALSE,);
        }
        if (_selectors[0] == _functionSelector) {
            return (TRUE,);
        }
        return _is_implemented(_selectors_len - 1, _selectors + 1, _functionSelector);
    }

    func _facetFunctionSelectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _facet: felt
    ) -> (res_len: felt, res: felt*) {
        alloc_locals;
        let (local no_param: felt*) = alloc();
        let (r_len, r) = library_call(
            class_hash=_facet,
            function_selector=FUNCTION_SELECTORS.FACET.__get_function_selectors__,
            calldata_size=NULL,
            calldata=no_param,
        );
        return (r_len, r);
    }

    func _diamondCut{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*
    ) -> () {
        if (_facetCutAction == FacetCutAction.Add) {
            _add_facet(_address, _init, _calldata_len, _calldata);
        } else {
            _remove_facet(_address);
        }
        return ();
    }

    func _get_facet_key_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> felt {
        let (facet_key) = facet_key_.read();
        return facet_key;
    }

    func _set_facet_key_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _facet_key: felt
    ) {
        facet_key_.write(_facet_key);
        return ();
    }

    func _get_root_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        let (root) = root_.read();
        return root;
    }

    func _set_root_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_root: felt) {
        root_.write(_root);
        return ();
    }

    func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (r) = root_.read();
        let tokenId = getRootTokenId();
        let (owner) = IERC721.ownerOf(r, tokenId);
        return owner;
    }

    func getRootTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> Uint256 {
        alloc_locals;
        let (self) = get_contract_address();
        let (high, low) = split_felt(self);
        local tokenId: Uint256 = Uint256(low, high);
        return tokenId;
    }

    func _add_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_address: felt, _init: felt, _calldata_len: felt, _calldata: felt*) -> () {
        alloc_locals;
        let (r) = root_.read();
        // Get facets and append new facet
        let (facets_len, facets) = _facetAddresses();
        assert facets[facets_len] = _address;
        let (new_key) = IBFR.calculateKey(r, facets_len + 1, facets);
        facet_key_.write(new_key);
        initFacet(_address, _calldata_len, _calldata);
        return ();
    }

    func initFacet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class_hash: felt, calldata_len: felt, calldata: felt*
    ) -> () {
        library_call(
            class_hash=class_hash,
            function_selector=FUNCTION_SELECTORS.FACET.__init_facet__,
            calldata_size=calldata_len,
            calldata=calldata,
        );
        return ();
    }

    func _remove_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_address: felt) -> () {
        alloc_locals;
        let (key) = facet_key_.read();
        let (r) = root_.read();
        let (facets_len, facets) = _facetAddresses();
        // find it
        let (x) = _remove_facet_helper(facets_len, facets, _address, 0);
        let (local ptr: felt*) = alloc();
        memcpy(dst=ptr, src=facets, len=x);
        // if non-tail element is removed
        if (facets_len != x + 1) {
            memcpy(dst=ptr + x, src=facets + x + 1, len=facets_len - x - 1);  // TODO
        }
        if (r != 0) {
            let (new_key) = IBFR.calculateKey(r, facets_len - 1, ptr);
        } else {
            let (my_root) = get_contract_address();
            let (new_key) = IBFR.calculateKey(my_root, facets_len - 1, ptr);
        }
        facet_key_.write(new_key);
        return ();
    }

    func _remove_facet_helper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _f_len: felt, _f: felt*, _target: felt, _id: felt
    ) -> (res: felt) {
        if (_f_len == 0) {
            with_attr error_message("FACET NOT FOUND") {
                assert 1 = 0;
            }
        }
        if (_target == _f[0]) {
            return (_id,);
        }
        return _remove_facet_helper(_f_len - 1, _f + 1, _target, _id + 1);
    }

    func _setAlias{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _alias: felt, _alias_selector: felt, _assigned_selector
    ) {
        Assert.selector_exists(_assigned_selector);
        alias_.write(_alias_selector, _assigned_selector);
        SetAlias.emit(_alias, _alias_selector, _assigned_selector);
        return ();
    }

    func _getAlias{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt
    ) -> felt {
        let (alias) = alias_.read(_selector);
        return alias;
    }

    func _setFunctionFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _chargee: felt, _charger: felt, _amount: felt, _erc20_contract: felt
    ) {
        Assert.selector_exists(_chargee);
        function_fee_.write(_chargee, Fee(_charger, _amount, _erc20_contract));
        SetFunctionFee.emit(_chargee, _charger, _amount, _erc20_contract);
        return ();
    }

    func _charge_fee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO zk-sudo erc-20
        return ();
    }

    namespace Assert {
        func selector_exists(_class_hash: felt) {
            with_attr error_message("FUNCTION NOT FOUND") {
                assert_not_zero(_class_hash);
            }
            return ();
        }

        func facet_exists{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr,
        }(_facet: felt) {
            alloc_locals;
            let (facets_len, facets) = _facetAddresses();
            _remove_facet_helper(facets_len, facets, _facet, 0);
            return ();
        }

        func only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
            alloc_locals;
            let (caller) = get_caller_address();
            let owner = get_owner();
            with_attr error_message("NOT AUTHORIZED") {
                assert caller = owner;
            }
            return ();
        }
    }
}

namespace Library {
}
