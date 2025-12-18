FUNCTION ZFM_RFQ_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_RFQ) TYPE  ZTT_RFQ_863
*"----------------------------------------------------------------------

  zcl_vendor_portal_863=>get_rfqs(
    EXPORTING iv_vendor_id = iv_vendor_id
    IMPORTING et_rfq       = et_rfq
  ).

ENDFUNCTION.
