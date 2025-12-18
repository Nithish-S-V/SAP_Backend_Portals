FUNCTION zfm_cdmemo_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"     VALUE(IV_FROM_DATE) TYPE  FKDAT
*"     VALUE(IV_TO_DATE) TYPE  SYDATUM
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_CDMEMO_HEAD) TYPE  ZCDMEMO_HEAD_TT_863
*"     VALUE(ET_CDMEMO_ITEM) TYPE  ZCDMEMO_ITEM_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr.

  " Default the date range if not provided
  DATA(lv_from_date) = COND #( WHEN iv_from_date IS INITIAL THEN '19000101' ELSE iv_from_date ).
  DATA(lv_to_date)   = COND #( WHEN iv_to_date   IS INITIAL THEN sy-datum   ELSE iv_to_date ).

  CLEAR: ev_success, ev_message.
  REFRESH: et_cdmemo_head, et_cdmemo_item.

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

  " Step 2: Select all data in one efficient query
  SELECT
      " Header Fields
      vbrk~vbeln AS document_number,
      vbrk~fkart AS document_type,
      CASE vbrk~fkart
         WHEN 'G2' THEN 'Credit Memo'
         WHEN 'L2' THEN 'Debit Memo'
         ELSE 'Other'
      END        AS document_type_text,
      vbrk~xblnr AS reference,
      vbrk~kunag AS customer_number,
      kna1~name1 AS customer_name,
      vbrk~fkdat AS billing_date,
      vbrk~erdat AS creation_date,
      vbrk~ernam AS created_by,
      vbrk~waerk AS currency,
      vbrk~netwr AS net_value,
      vbrk~mwsbk AS tax_amount,
      vbrk~vkorg AS sales_org,

      " Item Fields
      vbrp~posnr AS item_number,
      vbrp~matnr AS material_number,
      vbrp~arktx AS material_description,
      vbrp~fkimg AS billed_quantity,
      vbrp~vrkme AS unit_of_measure,
      vbrp~netwr AS item_net_value " Note: Using a different alias for item net value

    FROM vbrk
    INNER JOIN vbrp ON vbrk~vbeln = vbrp~vbeln
    INNER JOIN kna1 ON vbrk~kunag = kna1~kunnr
    INTO TABLE @DATA(lt_combined_data)
    WHERE vbrk~kunag = @lv_kunnr
      AND vbrk~fkart IN ('G2', 'L2')
      AND vbrk~fkdat BETWEEN @lv_from_date AND @lv_to_date.

  IF sy-subrc = 0.
    " Step 3: Split the combined data into separate header and item tables
    LOOP AT lt_combined_data INTO DATA(ls_data).
      " Populate Header (only once per unique document number)
      READ TABLE et_cdmemo_head TRANSPORTING NO FIELDS WITH KEY document_number = ls_data-document_number.
      IF sy-subrc <> 0.
        APPEND CORRESPONDING #( ls_data ) TO et_cdmemo_head.
      ENDIF.

      " Populate Item
      " To match item structure, we need to move the item-specific net value
      DATA(ls_item) = CORRESPONDING zcdmemo_item_s_863( ls_data ).
      ls_item-net_value = ls_data-item_net_value.
      APPEND ls_item TO et_cdmemo_item.
    ENDLOOP.

    ev_success = 'X'.
    ev_message = 'Credit/Debit Memos retrieved successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No Credit/Debit Memos found for the given criteria.'.
  ENDIF.

ENDFUNCTION.
