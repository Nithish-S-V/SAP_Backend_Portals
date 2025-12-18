FUNCTION zfm_aging_summary_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ET_AGING_SUMMARY) TYPE  ZAGING_SUMMARY_TT_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr        TYPE kunnr,
        lt_open_items   TYPE TABLE OF bsid,
        ls_aging_result TYPE zaging_summary_s_863,
        lv_today        TYPE dats,
        lv_days_due     TYPE i.

  CLEAR: ev_success, ev_message.
  REFRESH et_aging_summary.
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

  " Step 2: Select all open items for this customer
  SELECT *
    FROM bsid
    INTO TABLE @lt_open_items
    WHERE kunnr = @lv_kunnr.

  IF sy-subrc = 0.
    LOOP AT lt_open_items INTO DATA(ls_item).
      lv_days_due = lv_today - ls_item-zfBDT.

      "******************************************************************
      "***                   IMPROVED BUCKET LOGIC                    ***
      "******************************************************************
      IF lv_days_due < 0.
        " This item is not yet due. It is 'Current'.
        ls_aging_result-current_due = ls_aging_result-current_due + ls_item-dmbtr.
      ELSEIF lv_days_due BETWEEN 0 AND 30.
        ls_aging_result-days_0_30 = ls_aging_result-days_0_30 + ls_item-dmbtr.
      ELSEIF lv_days_due BETWEEN 31 AND 60.
        ls_aging_result-days_31_60 = ls_aging_result-days_31_60 + ls_item-dmbtr.
      ELSEIF lv_days_due BETWEEN 61 AND 90.
        ls_aging_result-days_61_90 = ls_aging_result-days_61_90 + ls_item-dmbtr.
      ELSE. " This covers everything > 90
        ls_aging_result-days_91_plus = ls_aging_result-days_91_plus + ls_item-dmbtr.
      ENDIF.
      "******************************************************************

      ls_aging_result-total_due = ls_aging_result-total_due + ls_item-dmbtr.
      ls_aging_result-currency = ls_item-waers.
    ENDLOOP.

    APPEND ls_aging_result TO et_aging_summary.
    ev_success = 'X'.
    ev_message = 'Aging summary generated successfully.'.
  ELSE.
    ev_success = 'X'.
    ev_message = 'No open items found for this customer.'.
  ENDIF.

ENDFUNCTION.
