// SPDX-License-Identifier: MIT

struct FacetCut {
    facetAddress: felt,
    facetCutAction: felt,
}

// @dev Enum
struct FacetCutAction {
    Add: felt,
    Remove: felt,
}
