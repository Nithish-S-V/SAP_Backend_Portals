FUNCTION ZFM_INVOICE_PDF_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"     VALUE(IV_INVOICE_NO) TYPE  BELNR_D
*"  EXPORTING
*"     VALUE(EV_BASE64) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: lv_pdf_xstring TYPE xstring.

  " 1. Submit the Report to run in background
  SUBMIT ZREP_INVOICE_PDF_863
    WITH p_belnr = iv_invoice_no
    WITH p_lifnr = iv_vendor_id
    AND RETURN.

  " 2. Retrieve the PDF Binary from Memory
  IMPORT inv_pdf = lv_pdf_xstring FROM MEMORY ID 'ZMEM_INV_863'.

  " Clean up memory
  FREE MEMORY ID 'ZMEM_INV_863'.

  " Check if PDF was generated
  IF lv_pdf_xstring IS INITIAL.
    RETURN.
  ENDIF.

  " 3. Convert Binary PDF (XSTRING) to Base64 String
  " Angular needs Base64 to display the PDF
  CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
    EXPORTING
      input  = lv_pdf_xstring
    IMPORTING
      output = ev_base64.

ENDFUNCTION.
