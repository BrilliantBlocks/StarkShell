const ADD = 0
const REPLACE = 1
const REMOVE = 2


struct FacetCut:
    member address : felt
    member FacetCutAction : felt
    member functionSelectors_len : felt
    member functionSelectors : felt*
end
