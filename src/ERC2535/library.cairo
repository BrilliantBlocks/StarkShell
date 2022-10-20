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

from src.constants import (
    IERC165_ID,
    IERC20_ID,
    IERC721_ID,
    IERC1155_ID,
    IERC5114_ID,
    IDIAMONDLOUPE_ID,
    FUNCTION_SELECTORS,
    NULL,
)
from src.ERC2535.IDiamondCut import Fee, FacetCut, FacetCutAction, SetAlias, SetFunctionFee
from src.ERC721.IERC721 import IERC721
from src.BFR.IBFR import IBFR


/// @dev Store the address of the factory contract
/// @return Address of its parent smart contract
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

namespace Diamond {
    func _facetAddresses{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }() -> (res_len: felt, res: felt*) {
        alloc_locals;
        let (key: felt) = facet_key_.read();
        let (r: felt) = root_.read();
        let (f_len: felt, f: felt*) = IBFR.resolveKey(r, key);
        return (f_len, f);
    }

    func _facetAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(_functionSelector: felt) -> (res: felt) {
        alloc_locals;
        let (f_len: felt, f: felt*) = _facetAddresses();
        let (class_hash: felt) = _facet_address(f_len, f, _functionSelector);
        Assert.selector_exists(class_hash);
        return (res=class_hash);
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
    _facetCut_len: felt, _facetCut: FacetCut*, _calldata_len: felt, _calldata: felt*
    ) -> () {
        alloc_locals;
        if (_facetCut_len == 0) {
            with_attr error_message("OVERFULL CALLDATA") {
                assert _calldata_len = 0;
            }
            return ();
        }

        let (root) = root_.read();
        let (facets_len, facets) = _facetAddresses();

        let (local new_facet: felt*) = alloc();
        local new_key;
        if (_facetCut[0].facetCutAction == FacetCutAction.Add) {
            assert new_facet[0] = _facetCut[0].facetAddress;
            let (local ptr: felt*) = alloc();
            memcpy(dst=ptr, src=facets, len=facets_len);
            memcpy(dst=ptr + facets_len, src=new_facet, len=1);
            let (new_key) = IBFR.calculateKey(root, facets_len + 1, ptr);
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar syscall_ptr = syscall_ptr;
        } else {
            // find it
            let (x) = _remove_facet_helper(facets_len, facets, _facetCut[0].facetAddress, 0);
            let (local ptr: felt*) = alloc();
            memcpy(dst=ptr, src=facets, len=x);
            // if non-tail element is removed
            if (facets_len != x + 1) {
                memcpy(dst=ptr + x, src=facets + x + 1, len=facets_len - x - 1);  // TODO
            }
            let (new_key) = IBFR.calculateKey(root, facets_len - 1, ptr);
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar syscall_ptr = syscall_ptr;
        }

        facet_key_.write(new_key);

        let (local facetCutCalldata: felt*) = alloc();

        local facetCutCalldata_len;
        if (_calldata_len == 0) {
            assert facetCutCalldata_len = 0;
        } else {
            assert facetCutCalldata_len = _calldata[1];
            memcpy(dst=facetCutCalldata, src=_calldata + 1, len=facetCutCalldata_len);
        }

        let constructor_or_destructor = ( 1 - _facetCut[0].facetCutAction ) * FUNCTION_SELECTORS.FACET.__constructor__ + _facetCut[0].facetCutAction * FUNCTION_SELECTORS.FACET.__destructor__;
        library_call(
            class_hash=_facetCut[0].facetAddress,
            function_selector=constructor_or_destructor,
            calldata_size=facetCutCalldata_len,
            calldata=facetCutCalldata,
        );

        let (local new_calldata: felt*) =  alloc();
        let new_calldata_len = _calldata_len - facetCutCalldata_len;

        if (_calldata_len == 0) {
        } else {
            memcpy(dst=new_calldata, src=_calldata, len=1);
            memcpy(dst=new_calldata, src=_calldata + facetCutCalldata_len + 1, len=_calldata_len - facetCutCalldata_len - 1);
        }

        return _diamondCut(
            _facetCut_len - 1,
            _facetCut + FacetCut.SIZE,
            new_calldata_len,
            new_calldata,
        );
    }

    // TODO remove
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

    func _execute_calldata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class_hash: felt, calldata_len: felt, calldata: felt*
    ) -> () {
        library_call(
            class_hash=class_hash,
            function_selector=FUNCTION_SELECTORS.FACET.__constructor__,
            calldata_size=calldata_len,
            calldata=calldata,
        );
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

    func _supportsInterface{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }(interface_id: felt, facets_len: felt, facets: felt*) -> (res: felt) {
        alloc_locals;
        if (facets_len == 0) {
            return (res=FALSE);
        }
        let facet_supports_interface = _facet_supports_interface(facets[0], interface_id);
        if (facet_supports_interface == TRUE) {
            return (res=TRUE);
        }
        return _supportsInterface(interface_id, facets_len - 1, facets + 1);
    }

    func _find_token_facet{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }(facets_len: felt, facets: felt*) -> felt {
        if (facets_len == 0) {
            return NULL;
        }
        let is_token_facet = _any_token_facet(facets[0]);
        if (is_token_facet == TRUE) {
            return facets[0];
        }
        return _find_token_facet(facets_len - 1, facets + 1);
    }

    func _any_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _facet: felt
    ) -> felt {
        let is_erc20_facet = _facet_supports_interface(_facet, IERC20_ID);
        if (is_erc20_facet == TRUE) {
            return TRUE;
        }
        let is_erc721_facet = _facet_supports_interface(_facet, IERC721_ID);
        if (is_erc721_facet == TRUE) {
            return TRUE;
        }
        let is_erc1155_facet = _facet_supports_interface(_facet, IERC1155_ID);
        if (is_erc1155_facet == TRUE) {
            return TRUE;
        }
        let is_erc5114_facet = _facet_supports_interface(_facet, IERC5114_ID);
        if (is_erc5114_facet == TRUE) {
            return TRUE;
        }
        return FALSE;
    }

    func _facet_supports_interface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _facet: felt, _interface_id: felt
    ) -> felt {
        alloc_locals;
        let (local calldata: felt*) = alloc();
        assert calldata[0] = _interface_id;
        let (r_len, r) = library_call(
            class_hash=_facet,
            function_selector=FUNCTION_SELECTORS.FACET.__supports_interface__,
            calldata_size=1,
            calldata=calldata,
        );
        return r[0];
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
