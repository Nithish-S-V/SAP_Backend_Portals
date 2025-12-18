FUNCTION zfm_overallsales_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_OVERALL_SALES) TYPE  ZOVERALLSALES_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr.

  CLEAR: ev_success, ev_message.
  REFRESH et_overall_sales.

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

  "--- Step 2: Select RAW Sales Order Data ---
  SELECT vbak~vbeln, vbap~matnr, vbap~arktx, vbak~netwr, vbak~waerk, vbak~erdat
    FROM vbak
    INNER JOIN vbap ON vbak~vbeln = vbap~vbeln
    INTO TABLE @DATA(lt_raw_orders)
    WHERE vbak~kunnr = @lv_kunnr.

  "--- Step 3: Select RAW Billing Data ---
  SELECT vbeln, netwr, waerk, fkdat
    FROM vbrk
    INTO TABLE @DATA(lt_raw_billing)
    WHERE kunrg = @lv_kunnr.

  "--- Step 4: Process the RAW order data into the final format ---
  LOOP AT lt_raw_orders INTO DATA(ls_order).
    " For each raw order, create one line in our final table
    APPEND INITIAL LINE TO et_overall_sales ASSIGNING FIELD-SYMBOL(<fs_final_line>).

    " Move the data and fill in the placeholders
    <fs_final_line>-document_number     = ls_order-vbeln.
    <fs_final_line>-record_type         = 'ORDER'.
    <fs_final_line>-material_number     = ls_order-matnr.
    <fs_final_line>-material_description = ls_order-arktx.
    <fs_final_line>-net_value           = ls_order-netwr.
    <fs_final_line>-currency            = ls_order-waerk.
    <fs_final_line>-creation_date       = ls_order-erdat.
    <fs_final_line>-total_orders_value  = ls_order-netwr.
    " Billing fields remain initial (blank/zero)
  ENDLOOP.

  "--- Step 5: Process the RAW billing data into the final format ---
  LOOP AT lt_raw_billing INTO DATA(ls_billing).
    " For each raw billing doc, create one line in our final table
    APPEND INITIAL LINE TO et_overall_sales ASSIGNING <fs_final_line>.

    " Move the data and fill in the placeholders
    <fs_final_line>-document_number     = ls_billing-vbeln.
    <fs_final_line>-record_type         = 'BILLING'.
    <fs_final_line>-net_value           = ls_billing-netwr.
    <fs_final_line>-currency            = ls_billing-waerk.
    <fs_final_line>-billing_date        = ls_billing-fkdat.
    <fs_final_line>-total_billed_value  = ls_billing-netwr.
    " Order fields (material, creation_date etc.) remain initial
  ENDLOOP.

  "--- Step 6: Final check and success message ---
  IF et_overall_sales IS NOT INITIAL.
    ev_success = 'X'.
    ev_message = 'Overall sales data retrieved successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No sales or billing data found for this customer.'.
  ENDIF.

ENDFUNCTION.
