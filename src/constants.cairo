const ALL_ONES = 2 ** 251 - 1;
const NULL = 0;
const IERC165_ID = 0x01ffc9a7;
const IERC20_ID = 0x01ffc9a7;
const IERC721_ID = 0x80ac58cd;
const IERC1155_ID = 0x01ffc9a7;
const IERC5114_ID = 0x01ffc9a7;
const IERC721_RECEIVER_ID = 0x150b7a02;
const IACCOUNT_ID = 0xf10dbd44;
const IDIAMONDLOUPE_ID = 0x123;  // TODO
const IDIAMONDCUT_ID = 0x123;  // TODO


namespace FUNCTION_SELECTORS {
    namespace DIAMONDCUT {
        const diamondCut = 0xf3d1ef016a3319b5c905f7ed8ae0708b96b732c565c6058e6a4f0291032848;
    }

    namespace ERC721 {
        const approve = 0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c;
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const getApproved = 0xb180e2fe9f14914416216da76338ac0beb980443725c802af615f8431fdb1e;
        const isApprovedForAll = 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30;
        const ownerOf = 0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9;
        const safeTransferFrom = 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444;
        const setApprovalForAll = 0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a;
        const transferFrom = 0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20;
    }

    namespace FACET {
        const __get_function_selectors__ = 0x35802e5c93fa05f42af0eb6d6ed857d69b8010fe9d917bfd51f60ffcd2300d6;
        const __init_facet__ = 0x101d2ba76f87b0ae8750c488387d702c0b092c6c6e91348ccf5d6dc2d734818;
        const __supports_interface__ = 0x20f621f78ecca5435389efa53ca29525b75fe9745044ce3b56b4b1e6056d791;
    }

    namespace MINTDEPLOY {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
    }
}
