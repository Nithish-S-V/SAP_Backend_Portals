FUNCTION zfm_invoice_details_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_INVOICES) TYPE  ZINVOICE_DETAIL_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr. " Variable to hold the SAP Customer Number

  CLEAR: ev_success, ev_message.
  REFRESH et_invoices. " Always clear an exporting table at the start

  " Step 1: Securely find the SAP Customer Number (KUNNR) linked to our portal user
  SELECT SINGLE customer_number
    FROM zcust_login_863
    INTO @lv_kunnr
    WHERE user_id = @iv_user_id.

  IF sy-subrc <> 0 OR lv_kunnr IS INITIAL.
    ev_success = ' '.
    ev_message = 'Portal user not found or not linked to an SAP customer.'.
    RETURN.
  ENDIF.

  " Step 2: Select rich, detailed invoice data using the KUNNR we found
  SELECT
      vbrp~posnr       AS item_no,
      vbrk~vbeln       AS document_no,
      vbrk~fkdat       AS bill_date,
      vbrk~kunag       AS soldtopar,
      kna1~name1       AS customername,
      kna1~kunnr       AS customer_id,
      vbrp~matnr       AS mat_no,
      vbrp~arktx       AS mat_des,
      vbrp~netwr       AS netwr,
      vbrk~waerk       AS currency,
      vbrk~vkorg       AS sales_org,
      kna1~stras       AS street,
      kna1~ort01       AS city,
      kna1~land1       AS country,
      kna1~pstlz       AS postal

    INTO TABLE @et_invoices
    FROM vbrk
    INNER JOIN vbrp ON vbrk~vbeln = vbrp~vbeln
    INNER JOIN kna1 ON kna1~kunnr = vbrk~kunag
    WHERE vbrk~kunag = @lv_kunnr.

  " Check the result of the database select
  IF sy-subrc = 0.
    ev_success = 'X'.
    ev_message = 'Invoices retrieved successfully.'.
  ELSE.
    " This is NOT an error. A customer might not have any invoices.
    ev_success = 'X'.
    ev_message = 'No invoices found for this customer.'.
  ENDIF.

ENDFUNCTION.
