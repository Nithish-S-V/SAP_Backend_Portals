*&---------------------------------------------------------------------*
*& Report ZREP_INVOICE_PDF_863
*&---------------------------------------------------------------------*
REPORT ZREP_INVOICE_PDF_863.

* Data Declarations
DATA: lv_func       TYPE funcname,
      lv_output     TYPE sfpoutputparams,
      lv_docparams  TYPE sfpdocparams,
      lv_form       TYPE fpformoutput,
      it_invoice    TYPE ZTT_INV_PDF_863. " <--- Your Table Type

* Input Parameters (Passed from the FM)
PARAMETERS: p_belnr TYPE belnr_d,
            p_lifnr TYPE lifnr.

* 1. Fetch Data
* Note: Make sure the "AS ..." names match your Structure Fields exactly!
SELECT a~belnr AS invoice_num,
       a~bukrs AS comp_code,
       a~gjahr AS fiscal_year,
       a~bldat AS doc_date,
       a~budat AS posting_date,
       a~waers AS currency,
       a~blart AS doc_type,
       a~lifnr AS vendor_id,
       b~matnr AS material_no,
       b~buzei AS item_num,
       b~lbkum AS stock_qty,
       b~meins AS unit,
       b~wrbtr AS amount,
       c~name1 AS vendor_name,
       c~ort01 AS city,
       c~land1 AS country
  INTO CORRESPONDING FIELDS OF TABLE @it_invoice
  FROM rbkp AS a
  INNER JOIN rseg AS b
    ON a~belnr = b~belnr
   AND a~gjahr = b~gjahr
  INNER JOIN lfa1 AS c
    ON a~lifnr = c~lifnr
  WHERE a~belnr = @p_belnr
    AND a~lifnr = @p_lifnr.

IF it_invoice IS INITIAL.
  RETURN. " Stop if no data found
ENDIF.

* 2. Setup Adobe Form Options
lv_output-nodialog  = 'X'.   " Suppress Printer Popup
lv_output-getpdf    = 'X'.   " We want the PDF Binary, not a printout
lv_output-dest      = 'LP01'.
lv_docparams-langu  = sy-langu.

* 3. Get the Generated Function Module Name for your Form
CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
  EXPORTING
    i_name     = 'ZFORM_INVOICE_VEND_863' " <--- Verify your Form Name here
  IMPORTING
    e_funcname = lv_func.

* 4. Open Form Job
CALL FUNCTION 'FP_JOB_OPEN'
  CHANGING
    ie_outputparams = lv_output
  EXCEPTIONS
    OTHERS          = 1.

* 5. Call the Form (Pass the Data)
CALL FUNCTION lv_func
  EXPORTING
    /1bcdwb/docparams  = lv_docparams
    it_invoice         = it_invoice  " <--- Passing our Data Table
  IMPORTING
    /1bcdwb/formoutput = lv_form     " <--- Receiving the PDF
  EXCEPTIONS
    OTHERS             = 1.

* 6. Close Job
CALL FUNCTION 'FP_JOB_CLOSE'
  EXCEPTIONS
    OTHERS = 1.

* 7. EXPORT PDF Binary to SAP Memory
* The FM will pick it up from here using this ID
EXPORT inv_pdf = lv_form-pdf TO MEMORY ID 'ZMEM_INV_863'.
