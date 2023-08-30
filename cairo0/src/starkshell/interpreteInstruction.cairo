from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.components.facets.starkshell.structs import Primitive, Variable, Instruction

func interpreteInstruction() -> (res_len: felt, res: felt*) {
    alloc_locals;

    local assert_only_owner_keyword;
    local exec_keyword;
    local return_keyword;
    local calldata_id;
    local res_id;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.assert_only_owner_keyword = get_selector_from_name("__ZKLANG__ASSERT_ONLY_OWNER")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.exec_keyword = get_selector_from_name("__ZKLANG__EXEC")
        ids.calldata_id = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.res_id = get_selector_from_name("__ZKLANG__RES_VAR")
    %}

    // Init variables
    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar Calldata = Variable(calldata_id, 0, 0, 0);
    tempvar ResultVar = Variable(res_id, 0, 0, 0);

    // Diamond.assert_only_owner()
    tempvar instruction0 = Instruction(
        primitive=Primitive(0, assert_only_owner_keyword),
        input1=NULLvar,
        input2=NULLvar,
        output=NULLvar,
        );

    // res = exec(_program, _memory)
    tempvar instruction1 = Instruction(
        primitive=Primitive(0, exec_keyword),
        input1=Calldata,
        input2=NULLvar,
        output=ResultVar,
        );

    // return res
    tempvar instruction2 = Instruction(
        primitive=Primitive(0, return_keyword),
        input1=ResultVar,
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar memory_layout = (ResultVar);

    let instruction_len = 3 * Instruction.SIZE;
    let memory_layout_len = 1 * Variable.SIZE;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        instruction1,
        instruction2,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
