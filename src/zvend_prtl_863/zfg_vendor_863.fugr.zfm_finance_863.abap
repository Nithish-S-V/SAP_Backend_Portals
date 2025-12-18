FUNCTION ZFM_FINANCE_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_FINANCE) TYPE  ZTT_FIN_863
*"----------------------------------------------------------------------

  zcl_vendor_portal_863=>get_financials(
    EXPORTING iv_vendor_id = iv_vendor_id
    IMPORTING et_finance   = et_finance
  ).

ENDFUNCTION.
