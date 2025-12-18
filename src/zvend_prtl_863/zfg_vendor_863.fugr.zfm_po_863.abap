FUNCTION ZFM_PO_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_PO) TYPE  ZTT_PO_863
*"----------------------------------------------------------------------

  zcl_vendor_portal_863=>get_pos(
    EXPORTING iv_vendor_id = iv_vendor_id
    IMPORTING et_po        = et_po
  ).

ENDFUNCTION.
