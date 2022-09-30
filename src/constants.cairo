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
    const mint = 1329909728320632088402217562277154056711815095720684343816173432540100887380;
    const __init_facet__ = 0x101d2ba76f87b0ae8750c488387d702c0b092c6c6e91348ccf5d6dc2d734818;

    const __get_function_selectors__ = 1512441085964722374952022796893127750645761723326055054060620822669917618390;
    const diamondCut = 430792745303880346585957116707317276189779144684897836036710359506025130056;

    namespace ERC165 {
        const __supports_interface__ = 931805622773425597786679106116934086420304240757827569899985084286984705937;
    }

    namespace ERC721 {
        const safeTransferFrom = 1;
        const ownerOf = 73122117822990066614852869276021392412342625629800410280609241172256672489;
    }
}
