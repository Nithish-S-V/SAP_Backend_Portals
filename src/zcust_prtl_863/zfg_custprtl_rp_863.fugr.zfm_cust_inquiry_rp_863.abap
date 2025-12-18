FUNCTION zfm_cust_inquiry_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_INQUIRIES) TYPE  ZCUSTINQUIRY_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr. " SAP Customer Number

  CLEAR: ev_success, ev_message.
  REFRESH et_inquiries.

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
  " It combines the two SELECTs from the reference into one efficient query.
  SELECT
      vbap~vbeln,
      vbak~erdat,
      vbak~ernam,
      vbak~waerk,
      vbap~matnr,
      vbap~arktx,
      vbap~posnr,
      vbap~posar,
      vbap~netwr,
      vbap~vrkme,
      vbak~auart,
      vbak~angdt,
      vbak~bnddt
    FROM vbap
    INNER JOIN vbak ON vbak~vbeln = vbap~vbeln
    INTO CORRESPONDING FIELDS OF TABLE @et_inquiries
    WHERE vbak~kunnr = @lv_kunnr
      AND vbak~auart = 'AF'. " <-- Key logic from reference: 'AF' for Inquiry

  IF sy-subrc = 0.
    ev_success = 'X'.
    ev_message = 'Inquiries retrieved successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No inquiries found for this customer.'.
  ENDIF.

ENDFUNCTION.
