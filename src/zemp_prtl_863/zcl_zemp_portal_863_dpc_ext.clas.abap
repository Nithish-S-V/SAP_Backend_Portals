class ZCL_ZEMP_PORTAL_863_DPC_EXT definition
  public
  inheriting from ZCL_ZEMP_PORTAL_863_DPC
  create public .

public section.
protected section.

  methods AUTHSET_CREATE_ENTITY
    redefinition .
  methods EMPLOYEESET_GET_ENTITY
    redefinition .
  methods LEAVEBALANCESET_GET_ENTITYSET
    redefinition .
  methods LEAVEREQUESTSET_GET_ENTITYSET
    redefinition .
  methods PAYSLIPSET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZEMP_PORTAL_863_DPC_EXT IMPLEMENTATION.


  method AUTHSET_CREATE_ENTITY.
**TRY.
*CALL METHOD SUPER->AUTHSET_CREATE_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**    io_data_provider        =
**  IMPORTING
**    er_entity               =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.
DATA: ls_request     TYPE zcl_zemp_portal_863_mpc=>ts_auth,
        lv_db_password TYPE zemp_login_863-password, "Type from your table
        lv_pernr       TYPE pa0000-pernr,
        ls_pa0001      TYPE pa0001.

  " 1. Get the JSON data sent from Angular
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = ls_request
  ).

  " 2. FRS Check 1: Is Employee Active in Standard SAP (PA0000)?
   SELECT SINGLE pernr
    FROM pa0000
    INTO lv_pernr
    WHERE pernr = ls_request-empid.

  IF sy-subrc <> 0.
    " Employee not found or inactive
    ls_request-success = abap_false.
    ls_request-message = 'Employee ID is invalid or inactive.'.
    er_entity = ls_request.
    RETURN.
  ENDIF.

  " 3. FRS Check 2: Check Password in Custom Table (ZEMP_LOGIN_863)
  SELECT SINGLE password
    FROM zemp_login_863
    INTO lv_db_password
    WHERE pernr = ls_request-empid.

  IF sy-subrc <> 0.
    " User exists in SAP but not in Portal Table
    ls_request-success = abap_false.
    ls_request-message = 'User not registered for Portal.'.
  ELSEIF lv_db_password = ls_request-password.
    " --- SUCCESS ---
    ls_request-success = abap_true.
    ls_request-message = 'Login Successful'.

    " Optional: Fetch Name to say 'Welcome Name'
    SELECT SINGLE ename
      FROM pa0001
      INTO ls_request-fullname
      WHERE pernr = ls_request-empid
        AND endda >= sy-datum.
  ELSE.
    " --- WRONG PASSWORD ---
    ls_request-success = abap_false.
    ls_request-message = 'Incorrect Password.'.
  ENDIF.

  " 4. Send response back
  er_entity = ls_request.
  endmethod.


  METHOD employeeset_get_entity.
**TRY.
*CALL METHOD SUPER->EMPLOYEESET_GET_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_request_object       =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**  IMPORTING
**    er_entity               =
**    es_response_context     =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.

    DATA: lv_pernr  TYPE pernr_d,
          ls_pa0001 TYPE pa0001,
          ls_pa0002 TYPE pa0002,
          ls_pa0105 TYPE pa0105,
          ls_key    TYPE /iwbep/s_mgw_name_value_pair.

    " 1. Retrieve the Employee ID (PERNR) from the URL Keys
    READ TABLE it_key_tab INTO ls_key WITH KEY name = 'Pernr'.
    IF sy-subrc = 0.
      lv_pernr = ls_key-value.
    ENDIF.

    IF lv_pernr IS INITIAL.
      RETURN. " No ID provided
    ENDIF.

    " 2. Fetch Personal Data (Name, Gender, DOB)
    SELECT SINGLE *
      FROM pa0002
      INTO ls_pa0002
      WHERE pernr = lv_pernr
        AND endda >= sy-datum.

    " 3. Fetch Organizational Data (Position, Dept)
    SELECT SINGLE *
      FROM pa0001
      INTO ls_pa0001
      WHERE pernr = lv_pernr
        AND endda >= sy-datum.

    " 4. Fetch Email (Subtype 0010 - System User)
    SELECT SINGLE *
      FROM pa0105
      INTO ls_pa0105
      WHERE pernr = lv_pernr
        AND subty = '0010'
        AND endda >= sy-datum.

    " 5. Map Data to Output (er_entity)
    " 5. Map Data to Output (er_entity)
    er_entity-pernr     = lv_pernr.
    er_entity-fullname  = ls_pa0001-ename.
    er_entity-gender    = ls_pa0002-gesch.

    " 6. === MANUAL DATE-TO-TIMESTAMP CONVERSION (THE FIX) ===
    IF ls_pa0002-gbdat IS NOT INITIAL.
      CONVERT DATE ls_pa0002-gbdat
        INTO TIME STAMP er_entity-dob TIME ZONE 'UTC'.
    ENDIF.

    IF ls_pa0001-begda IS NOT INITIAL.
      CONVERT DATE ls_pa0001-begda
        INTO TIME STAMP er_entity-join_date TIME ZONE 'UTC'.
    ENDIF.

    " 7. Get Email
    IF ls_pa0105-usrid_long IS NOT INITIAL.
      er_entity-email = ls_pa0105-usrid_long.
    ELSE.
      er_entity-email = 'No Email Maintained'.
    ENDIF.

    " 8. Get Text Descriptions for Position & Department (Make it readable)
    " Get Position Name
    SELECT SINGLE plstx
      FROM t528t
      INTO er_entity-designation
      WHERE plans = ls_pa0001-plans
        AND sprsl = sy-langu. " Removed date check for simplicity

    " Get Org Unit Name (Department)
    SELECT SINGLE orgtx
      FROM t527x
      INTO er_entity-department
      WHERE orgeh = ls_pa0001-orgeh
        AND sprsl = sy-langu. " Removed date check for simplicity
    " 6. Get Email
    IF ls_pa0105-usrid_long IS NOT INITIAL.
      er_entity-email = ls_pa0105-usrid_long.
    ELSE.
      er_entity-email = 'No Email Maintained'.
    ENDIF.

    " 7. Get Text Descriptions for Position & Department (Make it readable)
    " Get Position Name
    SELECT SINGLE plstx
      FROM t528t
      INTO er_entity-designation
      WHERE plans = ls_pa0001-plans
        AND sprsl = sy-langu
        AND endda >= sy-datum.

    " Get Org Unit Name (Department)
    SELECT SINGLE orgtx
      FROM t527x
      INTO er_entity-department
      WHERE orgeh = ls_pa0001-orgeh
        AND sprsl = sy-langu
        AND endda >= sy-datum.


  ENDMETHOD.


  method LEAVEBALANCESET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->LEAVEBALANCESET_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.

  DATA: lr_pernr TYPE RANGE OF pernr_d,
        ls_filter TYPE /iwbep/s_mgw_select_option,
        ls_range  TYPE /iwbep/s_cod_select_option,
        lt_pa2006 TYPE TABLE OF pa2006,
        ls_entity LIKE LINE OF et_entityset.

  " 1. Read Filter (Pernr)
  READ TABLE it_filter_select_options INTO ls_filter WITH KEY property = 'Pernr'.
  IF sy-subrc = 0.
    LOOP AT ls_filter-select_options INTO ls_range.
      APPEND VALUE #( sign = ls_range-sign option = ls_range-option
                      low = ls_range-low high = ls_range-high ) TO lr_pernr.
    ENDLOOP.
  ENDIF.

  IF lr_pernr IS INITIAL.
    RETURN.
  ENDIF.

  " 2. Select Quotas (Valid today)
  SELECT * FROM pa2006 INTO TABLE lt_pa2006
    WHERE pernr IN lr_pernr.

  " 3. Map to Output
  LOOP AT lt_pa2006 INTO DATA(ls_2006).
    CLEAR ls_entity.
    ls_entity-pernr       = ls_2006-pernr.
    ls_entity-quota_type  = ls_2006-ktart.
    ls_entity-entitlement = ls_2006-anzhl. " Total Entitlement
    ls_entity-deduction   = ls_2006-kverb. " Used

    " Calculation: Available = Entitlement - Used
    ls_entity-balance     = ls_2006-anzhl - ls_2006-kverb.

    " 4. Get Description (e.g., 'Casual Leave')
    SELECT SINGLE ktext
      FROM t556b
      INTO ls_entity-quota_text
      WHERE ktart = ls_2006-ktart
        AND sprsl = sy-langu.

    APPEND ls_entity TO et_entityset.
  ENDLOOP.

  endmethod.


  METHOD leaverequestset_get_entityset.
**TRY.
*CALL METHOD SUPER->LEAVEREQUESTSET_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.

    DATA: lr_pernr  TYPE RANGE OF pernr_d,
          ls_filter TYPE /iwbep/s_mgw_select_option,
          ls_range  TYPE /iwbep/s_cod_select_option,
          lt_pa2001 TYPE TABLE OF pa2001,
          ls_entity LIKE LINE OF et_entityset.

    " 1. Read Filter from URL (Expected: $filter=Pernr eq '1001')
    READ TABLE it_filter_select_options INTO ls_filter WITH KEY property = 'Pernr'.
    IF sy-subrc = 0.
      LOOP AT ls_filter-select_options INTO ls_range.
        APPEND VALUE #( sign = ls_range-sign option = ls_range-option
                        low = ls_range-low high = ls_range-high ) TO lr_pernr.
      ENDLOOP.
    ENDIF.

    IF lr_pernr IS INITIAL.
      RETURN. " No Employee ID provided
    ENDIF.

    " 2. Select Absence Data
    SELECT * FROM pa2001 INTO TABLE lt_pa2001
      WHERE pernr IN lr_pernr
        AND endda >= '20200101' " Optional: Limit to recent years
      ORDER BY begda DESCENDING.

    " 3. Map to Output
    LOOP AT lt_pa2001 INTO DATA(ls_2001).
      CLEAR ls_entity.
      ls_entity-request_id = cl_system_uuid=>create_uuid_c32_static( ).
      ls_entity-pernr      = ls_2001-pernr.
      ls_entity-begda      = ls_2001-begda.
      ls_entity-endda      = ls_2001-endda.
      ls_entity-days_p     = ls_2001-abwtg. " Absence Days
      ls_entity-leave_type = ls_2001-awart.

      " Status: In SAP, if it's in PA2001, it is usually Active/Approved
      ls_entity-status     = 'Approved'.

      " 4. Get Description (e.g., 'Sick Leave')
      SELECT SINGLE atext
        FROM t554t
        INTO ls_entity-leave_text
        WHERE awart = ls_2001-awart
          AND sprsl = sy-langu.

      APPEND ls_entity TO et_entityset.
    ENDLOOP.

  ENDMETHOD.


  METHOD payslipset_get_entity.
**TRY.
*CALL METHOD SUPER->PAYSLIPSET_GET_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_request_object       =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**  IMPORTING
**    er_entity               =
**    es_response_context     =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.

    DATA: ls_key   TYPE /iwbep/s_mgw_name_value_pair,
          lv_pernr TYPE pernr_d,
          lv_year  TYPE gjahr,
          lv_month TYPE monat.

    DATA: ls_pa0008 TYPE pa0008.

    " Adobe Form Variables
    DATA: fp_outputparams TYPE sfpoutputparams,
          fp_formoutput   TYPE fpformoutput,
          lv_fm_name      TYPE rs38l_fnam,
          lv_form_name    TYPE fpname VALUE 'ZFORM_PAY_863'. " <--- Your Adobe Form Name

    " -----------------------------------------------------------
    " 1. Read Keys from URL (Pernr, PayYear, PayMonth)
    " -----------------------------------------------------------
    READ TABLE it_key_tab INTO ls_key WITH KEY name = 'Pernr'.
    IF sy-subrc = 0. lv_pernr = ls_key-value. ENDIF.

    READ TABLE it_key_tab INTO ls_key WITH KEY name = 'PayYear'.
    IF sy-subrc = 0. lv_year = ls_key-value. ENDIF.

    READ TABLE it_key_tab INTO ls_key WITH KEY name = 'PayMonth'.
    IF sy-subrc = 0. lv_month = ls_key-value. ENDIF.

    IF lv_pernr IS INITIAL. RETURN. ENDIF.

    " -----------------------------------------------------------
    " 2. Fetch Basic Salary Data (PA0008)
    " -----------------------------------------------------------
    SELECT SINGLE * FROM pa0008 INTO ls_pa0008
      WHERE pernr = lv_pernr
        AND endda >= sy-datum.

    er_entity-pernr     = lv_pernr.
    er_entity-pay_year  = lv_year.
    er_entity-pay_month = lv_month.
    er_entity-net_pay   = ls_pa0008-bet01. " Using Basic Pay as Net Pay for demo
    er_entity-currency  = ls_pa0008-waers.

    " -----------------------------------------------------------
    " 3. Generate PDF (Adobe Form)
    " -----------------------------------------------------------
    fp_outputparams-nodialog = 'X'. " Don't show popup
    fp_outputparams-getpdf   = 'X'. " We want the PDF data

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = fp_outputparams
      EXCEPTIONS
        OTHERS          = 1.

    IF sy-subrc = 0.
      TRY.
          CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
            EXPORTING
              i_name     = lv_form_name
            IMPORTING
              e_funcname = lv_fm_name.

          CALL FUNCTION lv_fm_name
            EXPORTING
              /1bcdwb/docparams  = VALUE sfpdocparams( )
              iv_pernr           = lv_pernr  " Ensure this matches SFP Interface
            IMPORTING
              /1bcdwb/formoutput = fp_formoutput
            EXCEPTIONS
              OTHERS             = 1.

        CATCH cx_root.

      ENDTRY.

      CALL FUNCTION 'FP_JOB_CLOSE'.
    ENDIF.

    " -----------------------------------------------------------
    " 4. Convert PDF Binary to Base64 String
    " -----------------------------------------------------------
    IF fp_formoutput-pdf IS NOT INITIAL.
      CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
        EXPORTING
          input  = fp_formoutput-pdf
        IMPORTING
          output = er_entity-pdf_content.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
