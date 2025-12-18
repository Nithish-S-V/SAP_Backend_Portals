FUNCTION zfm_saleorders_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_SALESORDERS) TYPE  ZSALESORDER_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr. " SAP Customer Number

  CLEAR: ev_success, ev_message.
  REFRESH et_salesorders.

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

  "*** NOTE: This is the new, high-performance SELECT statement. ***
  " It combines the logic from the reference into one efficient query.
  SELECT
      vbak~vbeln,
      vbak~erdat,
      vbak~ernam,
      vbak~auart,
      vbap~matnr,
      vbap~arktx,
      vbap~posnr,
      vbap~netwr,
      vbak~waerk
    FROM vbak
    INNER JOIN vbap ON vbak~vbeln = vbap~vbeln
    INTO CORRESPONDING FIELDS OF TABLE @et_salesorders
    WHERE vbak~kunnr = @lv_kunnr
      AND vbak~auart = 'TA'. " <-- Key logic from reference: 'TA' for Standard Order

  IF sy-subrc = 0.
    ev_success = 'X'.
    ev_message = 'Sales Orders retrieved successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No Sales Orders found for this customer.'.
  ENDIF.

ENDFUNCTION.
