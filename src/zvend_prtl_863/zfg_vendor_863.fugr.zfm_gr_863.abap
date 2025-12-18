FUNCTION ZFM_GR_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VENDOR_ID) TYPE  LIFNR
*"  EXPORTING
*"     VALUE(ET_GR) TYPE  ZTT_GR_863
*"----------------------------------------------------------------------

  DATA: lv_vendor_padded TYPE lifnr.

  " 1. Handle Leading Zeros (Equivalent to LPAD in SQL)
  " This converts '100000' -> '0000100000' to match the database
  lv_vendor_padded = iv_vendor_id.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_vendor_padded
    IMPORTING
      output = lv_vendor_padded.

  " 2. Select directly from MSEG
  " In S/4HANA, MSEG has the field BUDAT_MKPF, so we don't need a Join.
  SELECT mblnr AS mat_doc_num,
         mjahr AS fiscal_year,
         bukrs AS comp_code,
         lifnr AS vendor_id,
         matnr AS material_no,
         werks AS plant,
         budat_mkpf AS posting_date
    FROM mseg
    INTO CORRESPONDING FIELDS OF TABLE @et_gr
    WHERE lifnr = @lv_vendor_padded
      AND bwart = '101'.

ENDFUNCTION.
