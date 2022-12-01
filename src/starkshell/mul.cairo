from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.common.table import Table
from src.zkode.facets.starkshell.structs import Primitive, Variable, Instruction

func mul(_x: felt, _y: felt) -> (res_len: felt, res: felt*) {
    alloc_locals;

    local return_keyword;
    local mul_keyword;
    local calldata_id;
    local mulvar_id;
    local starkshell_hash;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.mul_keyword = get_selector_from_name("__ZKLANG__MUL")
        ids.calldata_id = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.mulvar_id = get_selector_from_name("my_res_variable")

        import os
        ids.starkshell_hash = int(os.getenv("STARKSHELL_HASH"), 16)
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);
    tempvar Calldata = Variable(calldata_id, 0, 0, 0);
    tempvar mulvar = Variable(mulvar_id, 0, 0, 0);

    tempvar instruction0 = Instruction(
        primitive=Primitive(starkshell_hash, mul_keyword),
        input1=Calldata,
        input2=NULLvar,
        output=mulvar,
        );

    tempvar instruction1 = Instruction(
        primitive=Primitive(starkshell_hash, return_keyword),
        input1=mulvar,
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar program = new (instruction0, instruction1);
    tempvar memory = new (mulvar);
    tempvar calldata = new (_x, _y);

    local program_len = 2 * Instruction.SIZE;
    local memory_len = 1 * Variable.SIZE;
    local calldata_len = 2;

    let (local felt_code: felt*) = alloc();
    let felt_code_len = 0;
    let felt_code_len = Table.add_row(felt_code_len, felt_code, program_len, program);
    let felt_code_len = Table.add_row(felt_code_len, felt_code, memory_len, memory);
    let felt_code_len = Table.add_row(felt_code_len, felt_code, calldata_len, calldata);

    return (felt_code_len, felt_code);
}
