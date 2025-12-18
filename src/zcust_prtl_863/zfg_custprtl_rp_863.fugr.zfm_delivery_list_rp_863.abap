FUNCTION zfm_delivery_list_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_DELIVERIES) TYPE  ZLISTOFDELIVERY_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr. " SAP Customer Number

  CLEAR: ev_success, ev_message.
  REFRESH et_deliveries.

  " Step 1: Securely find the SAP Customer Number (KUNNR)
  SELECT SINGLE customer_number
    FROM zcust_login_863
    INTO @lv_kunnr
    WHERE user_id = @iv_user_id.

  IF sy-subrc <> 0 OR lv_kunnr IS INITIAL.
    ev_success = ' '.
    ev_message = 'Portal user not found or not linked to an SAP customer.'.
    RETURN.
  ENDIF.

  "*** NOTE: We are renaming the fields using AS to match our user-friendly structure ***
  SELECT
      likp~vbeln,
      likp~kunnr,
      likp~vstel,
      likp~ernam,
      likp~erdat,
      lips~posnr,
      lips~matnr,
      lips~arktx,
      lips~lfimg,
      lips~vrkme
   INTO CORRESPONDING FIELDS OF TABLE @et_deliveries
   FROM likp INNER JOIN lips
     ON likp~vbeln = lips~vbeln
   WHERE likp~kunnr = @lv_kunnr.

  IF sy-subrc = 0.
    ev_success = 'X'.
    ev_message = 'Deliveries retrieved successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No deliveries found for this customer.'.
  ENDIF.

ENDFUNCTION.
