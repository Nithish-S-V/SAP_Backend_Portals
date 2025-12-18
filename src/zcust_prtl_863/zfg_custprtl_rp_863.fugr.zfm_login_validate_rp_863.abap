FUNCTION zfm_login_validate_rp_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USERNAME) TYPE  STRING
*"     VALUE(IV_PASSWORD) TYPE  STRING
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(EV_CUSTOMER_ID) TYPE  ZDE_CUSTID_863
*"----------------------------------------------------------------------

  DATA: ls_portal_user TYPE zcust_login_863.

  "*** FIX #1: Added the new export parameter to the CLEAR statement ***
  CLEAR: ev_success, ev_message, ev_customer_id.

  " --- Step 1: Check for the portal user and validate the password ---
  SELECT SINGLE *
    FROM zcust_login_863
    INTO @ls_portal_user
    WHERE username = @iv_username.

  IF sy-subrc <> 0.
    ev_success = ' '.
    ev_message = 'Invalid username or password.'.
    RETURN.
  ENDIF.

  IF ls_portal_user-password <> iv_password.
    ev_success = ' '.
    ev_message = 'Invalid username or password.'.
    RETURN.
  ENDIF.

  " --- Step 2: Check if the linked customer is a valid customer in the standard SAP table ---
  IF ls_portal_user-customer_number IS INITIAL.
    ev_success = ' '.
    ev_message = 'Login failed: Portal account is not linked to a valid SAP customer.'.
    RETURN.
  ENDIF.

  SELECT SINGLE @abap_true
    FROM kna1
    INTO @DATA(lv_exists)
    WHERE kunnr = @ls_portal_user-customer_number.

  IF sy-subrc <> 0.
    ev_success = ' '.
    ev_message = 'Login failed: The linked SAP customer account does not exist or is inactive.'.
    RETURN.
  ENDIF.

  " --- If we have reached this point, all checks have passed. ---
  ev_success = 'X'.
  ev_message = 'Login Successful.'.
  ev_customer_id = ls_portal_user-user_id.
  "******************************************************************

ENDFUNCTION.
