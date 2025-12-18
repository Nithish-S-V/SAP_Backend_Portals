FUNCTION ZFM_PROFILE_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_PROFILE) TYPE  ZTT_PROFILE_863
*"----------------------------------------------------------------------

  zcl_vendor_portal_863=>get_profile(
    EXPORTING iv_vendor_id = iv_vendor_id
    IMPORTING et_profile   = et_profile
  ).

ENDFUNCTION.
