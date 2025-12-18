FUNCTION zfm_aging_detail_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_AGING_DETAIL) TYPE  ZAGING_DETAIL_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr      TYPE kunnr,
        lt_open_items TYPE TABLE OF bsid,
        ls_aging_line TYPE zaging_detail_s_863,
        lv_today      TYPE dats.

  CLEAR: ev_success, ev_message.
  REFRESH et_aging_detail.
  lv_today = sy-datum.

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

  " Step 2: Select all open items for this customer from table BSID
  SELECT *
    FROM bsid
    INTO TABLE @lt_open_items
    WHERE kunnr = @lv_kunnr.

  IF sy-subrc = 0.
    " Step 3: Loop, calculate age, and map to user-friendly structure
    LOOP AT lt_open_items INTO DATA(ls_item).
      CLEAR ls_aging_line.

      ls_aging_line-invoice_number = ls_item-vbeln.
      ls_aging_line-billing_date   = ls_item-bldat.
      ls_aging_line-due_date       = ls_item-zfbdt.
      ls_aging_line-amount_due     = ls_item-dmbtr.
      ls_aging_line-currency       = ls_item-waers.

      IF lv_today > ls_item-zfbdt.
        ls_aging_line-days_overdue = lv_today - ls_item-zfbdt.
      ELSE.
        ls_aging_line-days_overdue = 0.
      ENDIF.

      APPEND ls_aging_line TO et_aging_detail.
    ENDLOOP.

    ev_success = 'X'.
    ev_message = 'Detailed aging report generated successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No open items found for this customer.'.
  ENDIF.

ENDFUNCTION.
