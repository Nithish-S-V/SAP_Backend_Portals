class ZCL_ZEHSM_PORTAL_863_DPC_EXT definition
  public
  inheriting from ZCL_ZEHSM_PORTAL_863_DPC
  create public .

public section.
protected section.

  methods INCIDENTSET_GET_ENTITYSET
    redefinition .
  methods LOGINSET_GET_ENTITY
    redefinition .
  methods PROFILESET_GET_ENTITY
    redefinition .
  methods RISKSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZEHSM_PORTAL_863_DPC_EXT IMPLEMENTATION.


  method INCIDENTSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->INCIDENTSET_GET_ENTITYSET
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
DATA: lv_employeeid      TYPE persno,
        lt_incidents       TYPE zcl_ehsm_amdp_863=>tt_incidents,
        ls_incident_result TYPE zehsm_incident_863_s. " Use the global structure for entityset

  " Extract EmployeeId from filter options
  LOOP AT it_filter_select_options INTO DATA(ls_filter_option).
    IF ls_filter_option-property = 'EmployeeId'.
      READ TABLE ls_filter_option-select_options INTO DATA(ls_select_option) INDEX 1.
      IF sy-subrc = 0.
        lv_employeeid = ls_select_option-low.
      ENDIF.
      EXIT.
    ENDIF.
  ENDLOOP.

  " Format Employee ID (pad with leading zeros if necessary)
  IF lv_employeeid IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_employeeid
      IMPORTING
        output = lv_employeeid.
  ENDIF.

  IF lv_employeeid IS INITIAL.
    " Handle error or return empty set if employee ID is not provided
    RETURN.
  ENDIF.

  " Call the AMDP method to get incidents
  CALL METHOD zcl_ehsm_amdp_863=>get_incidents
    EXPORTING
      iv_client    = sy-mandt
      iv_employeeid = lv_employeeid
    IMPORTING
      et_incidents = lt_incidents.

  " Map AMDP results to OData entity set
  LOOP AT lt_incidents INTO ls_incident_result.
    " --- START OF ADDITION ---
    " Convert initial date '00000000' to blank for nullable OData properties
    IF ls_incident_result-completion_date = '00000000'.
      CLEAR ls_incident_result-completion_date.
    ENDIF.
    " Do the same for time fields if they can be initial and nullable
    IF ls_incident_result-completion_time = '000000'.
      CLEAR ls_incident_result-completion_time.
    ENDIF.
    IF ls_incident_result-incident_date = '00000000'.
      CLEAR ls_incident_result-incident_date.
    ENDIF.
    IF ls_incident_result-incident_time = '000000'.
      CLEAR ls_incident_result-incident_time.
    ENDIF.
    " --- END OF ADDITION ---

    APPEND ls_incident_result TO et_entityset.
  ENDLOOP.

  endmethod.


  method LOGINSET_GET_ENTITY.
**TRY.
*CALL METHOD SUPER->LOGINSET_GET_ENTITY
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
DATA: lv_employee_id TYPE z_username_863_de,
        lv_password    TYPE z_userpass_863_de,
        ls_key_tab     TYPE /iwbep/s_mgw_name_value_pair.

  " Extract Employee ID and Password from the request keys
  LOOP AT it_key_tab INTO ls_key_tab.
    CASE ls_key_tab-name.
      WHEN 'EmployeeId'.
        lv_employee_id = ls_key_tab-value.
      WHEN 'Password'.
        lv_password = ls_key_tab-value.
    ENDCASE.
  ENDLOOP.

  " Format Employee ID (pad with leading zeros if necessary)
  " Using CONVERSION_EXIT_ALPHA_INPUT is common for PERNR fields
  IF lv_employee_id IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_employee_id
      IMPORTING
        output = lv_employee_id.
  ENDIF.

  " Check credentials against the custom login table
  SELECT SINGLE * FROM zdt_ehsm_lgn_863 INTO @DATA(ls_auth)
    WHERE employee_id = @lv_employee_id
      AND password    = @lv_password.

  " Populate the entity with login status
  CLEAR er_entity.
  er_entity-employee_id = lv_employee_id.
  IF sy-subrc = 0.
    er_entity-password    = lv_password. " Return password if successful (consider security implications)
    er_entity-status      = 'Success'.
  ELSE.
    er_entity-password    = ''. " Do not return password on failure
    er_entity-status      = 'Invalid'.
  ENDIF.
  endmethod.


  method PROFILESET_GET_ENTITY.
**TRY.
*CALL METHOD SUPER->PROFILESET_GET_ENTITY
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
  DATA: lv_employeeid    TYPE persno,
        lt_profile       TYPE zcl_ehsm_amdp_863=>tt_profile,
        ls_profile_entry TYPE zehsm_profile_863_s,
        ls_key_tab       TYPE /iwbep/s_mgw_name_value_pair.

  " Extract EmployeeId from key tab
  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'EmployeeId'.
  IF sy-subrc = 0.
    lv_employeeid = ls_key_tab-value.
  ENDIF.

  " Format Employee ID
  IF lv_employeeid IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_employeeid
      IMPORTING
        output = lv_employeeid.
  ENDIF.

  IF lv_employeeid IS INITIAL.
    " Handle error or return empty if employee ID is not provided
    RETURN.
  ENDIF.

  " Call the AMDP method to get profile
  CALL METHOD zcl_ehsm_amdp_863=>get_profile
    EXPORTING
      iv_client    = sy-mandt
      iv_employeeid = lv_employeeid
    IMPORTING
      et_profile   = lt_profile.

  " Return the first (and only expected) entry
  READ TABLE lt_profile INTO ls_profile_entry INDEX 1.
  IF sy-subrc = 0.
    er_entity = ls_profile_entry.
  ENDIF.

  endmethod.


  method RISKSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->RISKSET_GET_ENTITYSET
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
DATA: lv_employeeid    TYPE persno,
        lt_risks         TYPE zcl_ehsm_amdp_863=>tt_risks,
        ls_risk_result   TYPE zehsm_risk_863_s. " Use the global structure for entityset

  " Extract EmployeeId from filter options
  LOOP AT it_filter_select_options INTO DATA(ls_filter_option).
    IF ls_filter_option-property = 'EmployeeId'.
      READ TABLE ls_filter_option-select_options INTO DATA(ls_select_option) INDEX 1.
      IF sy-subrc = 0.
        lv_employeeid = ls_select_option-low.
      ENDIF.
      EXIT.
    ENDIF.
  ENDLOOP.

  " Format Employee ID
  IF lv_employeeid IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_employeeid
      IMPORTING
        output = lv_employeeid.
  ENDIF.

  IF lv_employeeid IS INITIAL.
    " Handle error or return empty set if employee ID is not provided
    RETURN.
  ENDIF.

  " Call the AMDP method to get risks
  CALL METHOD zcl_ehsm_amdp_863=>get_risks
    EXPORTING
      iv_client    = sy-mandt
      iv_employeeid = lv_employeeid
    IMPORTING
      et_risks     = lt_risks.

  " Map AMDP results to OData entity set
  LOOP AT lt_risks INTO ls_risk_result.
    APPEND ls_risk_result TO et_entityset.
  ENDLOOP.
  endmethod.
ENDCLASS.
