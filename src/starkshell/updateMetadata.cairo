from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zkode.constants import FUNCTION_SELECTORS
from src.zkode.facets.starkshell.structs import Primitive, Variable, Instruction

func updateMetadata() -> (res_len: felt, res: felt*) {
    alloc_locals;

    local return_keyword;
    local calldata_id;
    local event_prmtv;
    local felt_to_uint256_prmtv;
    local call_contract_prmtv;
    local assert_eq_prmtv;
    local filter_var_prmtv;
    local token_id;
    local this_address_var;
    local ownerOf_data;
    local ownerOf_res;
    local noop_prmtv;
    local root_var;
    local caller_address_var;
    local event_data;
    local range1;
    local range2;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.calldata_id = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.event_prmtv = get_selector_from_name("__ZKLANG__EVENT")
        ids.felt_to_uint256_prmtv = get_selector_from_name("__ZKLANG__FELT_TO_UINT256")
        ids.call_contract_prmtv = get_selector_from_name("__ZKLANG__CALL_CONTRACT")
        ids.assert_eq_prmtv = get_selector_from_name("__ZKLANG__ASSERT_EQ")
        ids.filter_var_prmtv = get_selector_from_name("__ZKLANG__FILTER_VAR")
        ids.token_id = get_selector_from_name("tokenId")
        ids.this_address_var = get_selector_from_name("__ZKLANG__CONTRACT_ADDRESS_VAR")
        ids.ownerOf_res = get_selector_from_name("ownerOf_res")
        ids.ownerOf_data = get_selector_from_name("ownerOf_data")
        ids.noop_prmtv = get_selector_from_name("__ZKLANG__NOOP")
        ids.root_var = get_selector_from_name("rootVar")
        ids.event_data = get_selector_from_name("event_data")
        ids.caller_address_var = get_selector_from_name("__ZKLANG__CALLER_ADDRESS_VAR")
        ids.range1 = get_selector_from_name("range1")
        ids.range2 = get_selector_from_name("range2")
    %}

    // Declare special variables
    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar Calldata = Variable(calldata_id, 0, 0, 0);
    tempvar ContractAddressVar = Variable(this_address_var, 0, 0, 0);
    tempvar CallerAddressVar = Variable(caller_address_var, 0, 0, 0);
    // Declare variables
    tempvar rangeVar1 = Variable(range1, 0, 0, 2);
    tempvar rangeVar2 = Variable(range2, 0, 0, 2);
    tempvar ownerOf_selector = Variable(FUNCTION_SELECTORS.ERC721.ownerOf, 0, 0, 1);  // TODO ownerOf
    tempvar rootVar = Variable(root_var, 0, 0, 0);

    tempvar TokenIdVar = Variable(token_id, 0, 0, 0);
    tempvar ownerOfDataVar = Variable(ownerOf_res, 0, 0, 0);
    tempvar OwnerVar = Variable(ownerOf_res, 0, 0, 0);
    tempvar EventDataVar = Variable(event_data, 0, 0, 0);

    // push calldata
    tempvar instruction0 = Instruction(
        primitive=Primitive(0, noop_prmtv),
        input1=Calldata,
        input2=NULLvar,
        output=Calldata,
        );

    // filter token id from calldata
    tempvar instruction1 = Instruction(
        primitive=Primitive(0, filter_var_prmtv),
        input1=rangeVar1,
        input2=Calldata,
        output=TokenIdVar,
        );

    // root + ownerOf_selector = IERC721.ownerOf()
    tempvar instruction2 = Instruction(
        primitive=Primitive(0, noop_prmtv),
        input1=rootVar,
        input2=ownerOf_selector,
        output=ownerOfDataVar,
        );

    // pop ownerOfDataVar
    tempvar instruction3 = Instruction(
        primitive=Primitive(0, noop_prmtv),
        input1=NULLvar,
        input2=ownerOfDataVar,
        output=ownerOfDataVar,
        );

    // IERC721.ownerOf(root, token_id)
    tempvar instruction4 = Instruction(
        primitive=Primitive(0, call_contract_prmtv),
        input1=ownerOfDataVar,
        input2=TokenIdVar,
        output=OwnerVar,
        );

    // pop OwnerVar
    tempvar instruction5 = Instruction(
        primitive=Primitive(0, noop_prmtv),
        input1=NULLvar,
        input2=OwnerVar,
        output=OwnerVar,
        );

    // assert owner = caller
    tempvar instruction6 = Instruction(
        primitive=Primitive(0, assert_eq_prmtv),
        input1=OwnerVar,
        input2=CallerAddressVar,
        output=NULLvar,
        );

    // filter values from token id
    tempvar instruction7 = Instruction(
        primitive=Primitive(0, filter_var_prmtv),
        input1=rangeVar2,
        input2=Calldata,
        output=EventDataVar,
        );

    // emit() (maybe event_data needs push)
    tempvar instruction8 = Instruction(
        primitive=Primitive(0, event_prmtv),
        input1=EventDataVar,
        input2=NULLvar,
        output=NULLvar,
        );

    // return ()
    tempvar instruction9 = Instruction(
        primitive=Primitive(0, return_keyword),
        input1=NULLvar,
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar memory_layout = (
        rangeVar1, 0, 2,
        rangeVar2, 2, 3,
        ownerOf_selector, FUNCTION_SELECTORS.ERC721.ownerOf,
        TokenIdVar,
        ownerOfDataVar,
        rootVar,
        EventDataVar,
        );

    let instruction_len = 10 * Instruction.SIZE;
    let memory_layout_len = 7 * Variable.SIZE + 2 + 2 + 1;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        instruction1,
        instruction2,
        instruction3,
        instruction4,
        instruction5,
        instruction6,
        instruction7,
        instruction8,
        instruction9,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
