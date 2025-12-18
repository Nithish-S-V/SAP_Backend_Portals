FUNCTION zfm_invoice_pdf_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_INVOICE_NUMBER) TYPE  VBELN_VF
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(EV_PDF_BASE64) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: inv_formoutput TYPE fpformoutput.

  CLEAR: ev_success, ev_message, ev_pdf_base64.

  " Step 1: Call the report program in the background, passing the invoice number.
  " This exactly mirrors your reference logic.
  SUBMIT zrp_invoice_report_863
    WITH p_vbeln = iv_invoice_number
    AND RETURN.

  " Step 2: Import the PDF data that the report saved to memory.
  " NOTE: The Memory ID 'Z_CUSTPORTAL_PDF' must be used in the report as well.
  IMPORT lv_form TO inv_formoutput FROM MEMORY ID 'Z_CUSTPORTAL_PDF'.

  " Step 3: Free the memory ID immediately for clean-up.
  FREE MEMORY ID 'Z_CUSTPORTAL_PDF'.

  " Step 4: Check if the report successfully returned a PDF.
  IF inv_formoutput-pdf IS INITIAL.
    ev_success = ' '.
    ev_message = 'Failed to generate PDF. The background report did not return data.'.
    RETURN.
  ENDIF.

  " Step 5: Convert the binary PDF (XSTRING) to a Base64 STRING.
  " This uses the exact function from your working reference code.
  CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
    EXPORTING
      input  = inv_formoutput-pdf
    IMPORTING
      output = ev_pdf_base64.

  ev_success = 'X'.
  ev_message = 'PDF generated successfully.'.

ENDFUNCTION.
