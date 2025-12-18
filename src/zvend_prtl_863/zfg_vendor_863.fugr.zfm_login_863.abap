FUNCTION ZFM_LOGIN_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"     VALUE(IV_PASSWORD) TYPE  CHAR20
*"  EXPORTING
*"     VALUE(ET_RESPONSE) TYPE  ZTT_LOGIN_RES_863
*"----------------------------------------------------------------------

  " Call the AMDP Class Method
  zcl_vendor_portal_863=>validate_login(
    EXPORTING
      iv_vendor_id = iv_vendor_id
      iv_password  = iv_password
    IMPORTING
      et_response  = et_response
  ).

ENDFUNCTION.
