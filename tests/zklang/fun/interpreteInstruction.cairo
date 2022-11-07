%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zklang.library import Function, Instruction, Primitive, Variable

func interpreteInstruction() -> (res_len: felt, res: felt*) {
    alloc_locals;

    local assert_only_owner_keyword;
    local return_keyword;
    local calldata_id;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.assert_only_owner_keyword = get_selector_from_name("__ZKLANG__ASSERT_ONLY_OWNER")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.calldata_id = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar Calldata = Variable(calldata_id, 0, 0, 0);

    // Diamond.assert_only_owner()
    tempvar instruction0 = Instruction(
        primitive=Primitive(0, assert_only_owner_keyword),
        input1=NULLvar,
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar memory_layout = ();

    let instruction_len = 1 * Instruction.SIZE;
    let memory_layout_len = 0;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
// if memory_hash(_pid) != 0; do assert hash(_program, _memory) = memory_hash(_pid)
// res = exec _program + _new_instructions, _memory + _new_memory from _pc = &_new_instruction
// emit StateDelta(_pid, _new_instruction, _new_memory)
// process_.write(_pid, hash(_program + _new_instruction, _memory + _new_memory))
// emit Process(_pid,hash(_program + _new_instruction, _memory + _new_memory))
// return res
