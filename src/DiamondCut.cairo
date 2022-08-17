%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.structs import FacetCut


@event
func DiamondCut(_diamondCut_len: felt, _diamondCut: FacetCut*, _init: felt, _calldata_len: felt, _calldata: felt*):
end
