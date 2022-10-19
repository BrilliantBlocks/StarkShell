%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IERC721_ID

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
    return (res_len=8, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC721.balanceOf;
    dw FUNCTION_SELECTORS.ERC721.ownerOf;
    dw FUNCTION_SELECTORS.ERC721.getApproved;
    dw FUNCTION_SELECTORS.ERC721.isApprovedForAll;
    dw FUNCTION_SELECTORS.ERC721.approve;
    dw FUNCTION_SELECTORS.ERC721.setApprovalForAll;
    dw FUNCTION_SELECTORS.ERC721.transferFrom;
    dw FUNCTION_SELECTORS.ERC721.safeTransferFrom;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    if (_interface_id == IERC721_ID) {
        return (res=TRUE);
    }
    return (res=FALSE);
}
