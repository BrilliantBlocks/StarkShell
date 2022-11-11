from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zklang.structs import Primitive, Variable, Instruction

func mintContract() -> (res_len: felt, res: felt*) {
    alloc_locals;
    local deploy_primitive;
    local mint_primitive;
    local return_primitive;
    local calldata_var;
    local this_address_var;
    local call_contract_primitive;
    local merge_vars_primitive;
    local felt_to_uint256_primitive;
    local facet_key_var;
    local x_var;
    local diamond_addr_var;
    local tokenId_var;
    local caller_address_var;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.deploy_primitive = get_selector_from_name("__ZKLANG__DEPLOY")
        ids.return_primitive = get_selector_from_name("__ZKLANG__RETURN")
        ids.call_contract_primitive = get_selector_from_name("__ZKLANG__CALL_CONTRACT")
        ids.merge_vars_primitive = get_selector_from_name("__ZKLANG__MERGE_VARS")
        ids.mint_primitive = get_selector_from_name("mint")
        ids.calldata_var = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.this_address_var = get_selector_from_name("__ZKLANG__CONTRACT_ADDRESS_VAR")
        ids.caller_address_var = get_selector_from_name("__ZKLANG__CALLER_ADDRESS_VAR")
        ids.facet_key_var = get_selector_from_name("facet_key_var")
        ids.x_var = get_selector_from_name("x_var")
        ids.diamond_addr_var = get_selector_from_name("diamond_addr_var")
        ids.tokenId_var = get_selector_from_name("tokenId")
        ids.felt_to_uint256_primitive = get_selector_from_name("__ZKLANG__FELT_TO_UINT256")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    tempvar instruction0 = Instruction(
        primitive=Primitive(0, deploy_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(facet_key_var, 0, 0, 0),
        output=Variable(diamond_addr_var, 0, 0, 0),
        );

    tempvar instruction1 = Instruction(
        primitive=Primitive(0, felt_to_uint256_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(tokenId_var, 0, 0, 0),
        );

    tempvar instruction2 = Instruction(
        primitive=Primitive(0, mint_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(tokenId_var, 0, 0, 0),
        output=NULLvar,
        );

    tempvar instruction3 = Instruction(
        primitive=Primitive(0, call_contract_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(calldata_var, 0, 0, 0),
        output=NULLvar,
        );

    tempvar instruction4 = Instruction(
        primitive=Primitive(0, merge_vars_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(caller_address_var, 0, 0, 0),
        output=Variable(x_var, 0, 0, 0),
        );

    tempvar instruction5 = Instruction(
        primitive=Primitive(0, call_contract_primitive),
        input1=Variable(x_var, 0, 0, 0),
        input2=Variable(tokenId_var, 0, 0, 0),
        output=NULLvar,
        );

    tempvar instruction6 = Instruction(
        primitive=Primitive(0, return_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar facet_key = Variable(facet_key_var, 0, 0, 3);
    tempvar diamond_addr = Variable(diamond_addr_var, 0, 0, 0);
    tempvar tokenId = Variable(tokenId_var, 0, 0, 0);
    tempvar x = Variable(x_var, 0, 0, 0);

    tempvar memory_layout = (
        facet_key, 1, 0, 0,
        diamond_addr,
        tokenId,
        x,
        );

    let instruction_len = 7 * Instruction.SIZE;
    let memory_layout_len = 4 * Variable.SIZE + facet_key.data_len;
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
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
