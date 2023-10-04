MAX_CHARS_FELT = 31

def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(felt):
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode("ascii")


def str_to_felt_array(text):
    chunks = []
    for i in range(0, len(text), MAX_CHARS_FELT):
        str_chunk = text[i : i + MAX_CHARS_FELT]
        chunks.append(str_to_felt(str_chunk))
    return chunks


def felt_array_to_str(felt_array):
    res = ""
    for felt in felt_array[1:]:
        res += felt_to_str(felt).replace("\x00", "")
    return res
