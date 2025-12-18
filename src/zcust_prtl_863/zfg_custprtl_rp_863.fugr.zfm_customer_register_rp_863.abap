FUNCTION zfm_customer_register_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USERNAME) TYPE  ZDE_USERNAME_863
*"     VALUE(IV_PASSWORD) TYPE  ZDE_PASS_863
*"     VALUE(IV_CUSTOMER_NAME) TYPE  ZDE_CUSTNAME_863
*"     VALUE(IV_CUSTOMER_MAIL) TYPE  ZDE_CUSTMAIL_863
*"     VALUE(IV_CUSTOMER_NUMBER) TYPE  KUNNR  "*** ADDED ***
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(EV_CUSTOMER_ID) TYPE  NUMC10
*"----------------------------------------------------------------------

  DATA: ls_new_customer TYPE zcust_login_863,
        lv_cust_id      TYPE zcust_login_863-user_id.

  " First, check if the username already exists to prevent duplicates.
  SELECT SINGLE @abap_true
    FROM zcust_login_863
    INTO @DATA(lv_exists_user)
    WHERE username = @iv_username.

  IF sy-subrc = 0.
    ev_success = ' '.
    ev_message = 'Username already exists. Please choose another.'.
    RETURN.
  ENDIF.

  "*** NEW VALIDATION STEP ***
  " Check if the provided SAP Customer Number is a real customer.
  SELECT SINGLE @abap_true
    FROM kna1
    INTO @DATA(lv_exists_kunnr)
    WHERE kunnr = @iv_customer_number.

  IF sy-subrc <> 0.
    ev_success = ' '.
    ev_message = 'Registration failed: The provided SAP Customer Number is not valid.'.
    RETURN.
  ENDIF.
  "*** END NEW VALIDATION STEP ***


  " Get the next available portal ID from our Number Range Object
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZCUST_NR_8'
    IMPORTING
      number      = lv_cust_id
    EXCEPTIONS
      OTHERS      = 4.

  IF sy-subrc <> 0.
    ev_success = ' '.
    ev_message = 'Critical Error: Could not generate a new Customer ID.'.
    RETURN.
  ENDIF.

  " If we get here, all checks passed. Prepare the new record.
  ls_new_customer-user_id         = lv_cust_id.
  ls_new_customer-username        = iv_username.
  ls_new_customer-password        = iv_password.
  ls_new_customer-customer_name   = iv_customer_name.
  ls_new_customer-customer_mail   = iv_customer_mail.
  ls_new_customer-customer_number = iv_customer_number. "*** ADDED: Populate the verified customer number ***"

  " Insert the new record into the database table
  INSERT zcust_login_863 FROM ls_new_customer.

  IF sy-subrc = 0.
    ev_success     = 'X'.
    ev_message     = 'Customer successfully registered.'.
    ev_customer_id = lv_cust_id.
  ELSE.
    ev_success = ' '.
    ev_message = 'Error: Could not register customer.'.
  ENDIF.

ENDFUNCTION.
