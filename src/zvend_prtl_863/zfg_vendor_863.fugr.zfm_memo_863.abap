FUNCTION ZFM_MEMO_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_MEMOS) TYPE  ZTT_MEMO_863
*"----------------------------------------------------------------------

  zcl_vendor_portal_863=>get_memos(
    EXPORTING iv_vendor_id = iv_vendor_id
    IMPORTING et_memos     = et_memos
  ).

ENDFUNCTION.
