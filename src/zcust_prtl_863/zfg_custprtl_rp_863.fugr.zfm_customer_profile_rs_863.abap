FUNCTION zfm_customer_profile_rs_863.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_CUSTOMER_ID) TYPE  ZDE_CUSTID_863
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"     VALUE(ES_CUSTPROF) TYPE  ZCUSTOMER_PROFILE_S_863
*"----------------------------------------------------------------------

  DATA: lv_kunnr TYPE kunnr,
        lv_mail  TYPE zcust_login_863-customer_mail. " Variable for email

  CLEAR: ev_success, ev_message, es_custprof.

  " Step 1: Fetch the linked SAP Customer Number AND the portal email
  " from your custom login table using the provided portal USER_ID.
  SELECT SINGLE customer_number, customer_mail
    FROM zcust_login_863
    INTO (@lv_kunnr, @lv_mail)
    WHERE user_id = @iv_customer_id.

  IF sy-subrc <> 0 OR lv_kunnr IS INITIAL.
    ev_success = ' '.
    ev_message = 'Portal user not found or not linked to an SAP customer.'.
    RETURN.
  ENDIF.

  " Step 2: Immediately place the retrieved email into the final output structure.
  es_custprof-customer_mail = lv_mail.

  " Step 3: Now use the SAP Customer Number (KUNNR) to get the rest of the
  " profile data from the standard customer master table (KNA1).
  " The JOIN to the address table and the REGION field are now removed.
  SELECT SINGLE kna1~kunnr,
                kna1~adrnr,
                kna1~name1,
                kna1~ort01 AS city1,
                kna1~land1 AS country
    INTO CORRESPONDING FIELDS OF @es_custprof
    FROM kna1
    WHERE kna1~kunnr = @lv_kunnr.

  IF sy-subrc = 0.
    ev_success = 'X'.
    ev_message = 'Profile retrieved successfully.'.
  ELSE.
    ev_success = ' '.
    ev_message = 'Could not retrieve profile details from the customer.'.
  ENDIF.

ENDFUNCTION.
