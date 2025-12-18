REPORT zrp_invoice_report_863.

TYPE-POOLS: sfp.

" --- Data Declarations ---
DATA:
  lv_form         TYPE fpformoutput,
  i_header        TYPE zinvoice_pdf_head_s_863,
  i_items         TYPE zinvoice_pdf_item_tt_863,
  lv_func         TYPE funcname,
  ls_fp_outparams TYPE sfpoutputparams.

" --- This parameter receives the invoice number from the function module ---
PARAMETERS: p_vbeln TYPE vbeln OBLIGATORY.

" --- Data Selection (from your reference) ---
SELECT SINGLE
    vbrk~vbeln AS document_no, kna1~name1 AS customername, kna1~kunnr AS customer_id,
    kna1~stras AS street, kna1~ort01 AS city, kna1~land1 AS country, kna1~pstlz AS postal
  INTO CORRESPONDING FIELDS OF @i_header
  FROM vbrk
  INNER JOIN kna1 ON vbrk~kunag = kna1~kunnr
  WHERE vbrk~vbeln = @p_vbeln.

IF sy-subrc <> 0.
  RETURN. " Exit if header not found
ENDIF.

SELECT
    vbrp~posnr AS item_no, vbrk~fkdat AS bill_date, vbrk~kunag AS soldtopar,
    vbrp~matnr AS mat_no, vbrp~arktx AS mat_des, vbrp~netwr AS netwr, vbrk~waerk AS currency
  FROM vbrk
  INNER JOIN vbrp ON vbrk~vbeln = vbrp~vbeln
  INTO CORRESPONDING FIELDS OF TABLE @i_items
  WHERE vbrk~vbeln = @p_vbeln.

IF i_items IS INITIAL.
  RETURN. " Exit if no items found
ENDIF.

" --- Adobe Form Processing (from your reference) ---
TRY.
    CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
      EXPORTING
        i_name     = 'ZINVOICE_FORM_863'
      IMPORTING
        e_funcname = lv_func.

    ls_fp_outparams-nodialog = 'X'.
    ls_fp_outparams-getpdf   = 'M'.

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = ls_fp_outparams.

    CALL FUNCTION lv_func
      EXPORTING
        wa_header        = i_header
        lt_item          = i_items
      IMPORTING
        /1bcdwb/formoutput = lv_form
      EXCEPTIONS
        OTHERS           = 4.

    CALL FUNCTION 'FP_JOB_CLOSE'.

  CATCH cx_root.
    RETURN.
ENDTRY.

" --- Export to Memory (The most important step) ---
" This makes the PDF data available to the function module that called this report.
EXPORT lv_form TO MEMORY ID 'Z_CUSTPORTAL_PDF'.
