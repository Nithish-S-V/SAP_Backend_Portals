class ZCL_ZMAINT_PORTAL_863_DPC_EXT definition
  public
  inheriting from ZCL_ZMAINT_PORTAL_863_DPC
  create public .

public section.
protected section.

  methods LOGINSET_CREATE_ENTITY
    redefinition .
  methods NOTIFICATION_MAI_GET_ENTITYSET
    redefinition .
  methods PLANTLISTSET_GET_ENTITYSET
    redefinition .
  methods WORKORDERSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZMAINT_PORTAL_863_DPC_EXT IMPLEMENTATION.


  method LOGINSET_CREATE_ENTITY.
**TRY.
*CALL METHOD SUPER->LOGINSET_CREATE_ENTITY
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
    DATA: ls_request TYPE zlogin_s_863,
          ls_db      TYPE zmaint_login_863.

    " 1. Read JSON Body from Frontend
    io_data_provider->read_entry_data( IMPORTING es_data = ls_request ).

    " 2. Validate Credentials
    " Map friendly name 'EngineerID' to DB field 'MAINTENANCE_ENG'
    SELECT SINGLE * FROM zmaint_login_863
      INTO ls_db
      WHERE maintenance_eng = ls_request-engineerid
        AND password        = ls_request-password.

    " 3. Return Success or Failure
    IF sy-subrc = 0.
      er_entity-engineerid = ls_db-maintenance_eng.
      er_entity-message    = 'SUCCESS'.
      er_entity-password   = ''. " Security: Don't send pass back
    ELSE.
      er_entity-engineerid = ls_request-engineerid.
      er_entity-message    = 'INVALID'.
    ENDIF.
  endmethod.


METHOD notification_mai_get_entityset.
    DATA: lv_swerk       TYPE swerk,
          lt_viqmel      TYPE STANDARD TABLE OF viqmel,
          ls_viqmel      LIKE LINE OF lt_viqmel,
          ls_entity      TYPE znotifs_s_863,
          r_date_range   TYPE RANGE OF ausvn,
          ls_range       LIKE LINE OF r_date_range,
          lv_status_text TYPE char40.  " <--- FIX: Correct type for Status Function

    " 1. Parse Filters (Case Sensitive matches Metadata)
    LOOP AT it_filter_select_options INTO DATA(ls_filter).
      CASE ls_filter-property.
        WHEN 'Maintplant'.
          READ TABLE ls_filter-select_options INTO DATA(ls_so) INDEX 1.
          lv_swerk = ls_so-low.
        WHEN 'Startdate'.
          LOOP AT ls_filter-select_options INTO ls_so.
            ls_range-sign   = ls_so-sign.
            ls_range-option = ls_so-option.
            ls_range-low    = ls_so-low(8).
            ls_range-high   = ls_so-high(8).
            APPEND ls_range TO r_date_range.
          ENDLOOP.
      ENDCASE.
    ENDLOOP.

    IF lv_swerk IS NOT INITIAL.

      " 2. Select ONLY required fields (Prevents DB Crash)
      " Logic: Split selection to avoid passing empty range to DB
      IF r_date_range IS INITIAL.
        " No Date Filter
        SELECT qmnum iwerk iloan equnr ingrp ausvn qmart auztv artpr qmtxt priok arbpl swerk objnr
          FROM viqmel
          INTO CORRESPONDING FIELDS OF TABLE lt_viqmel
          WHERE swerk = lv_swerk.
      ELSE.
        " With Date Filter
        SELECT qmnum iwerk iloan equnr ingrp ausvn qmart auztv artpr qmtxt priok arbpl swerk objnr
          FROM viqmel
          INTO CORRESPONDING FIELDS OF TABLE lt_viqmel
          WHERE swerk = lv_swerk
            AND ausvn IN r_date_range.
      ENDIF.

      " 3. Map Data Manually
      LOOP AT lt_viqmel INTO ls_viqmel.
        CLEAR ls_entity.

        " Map Fields
        ls_entity-notificationid = ls_viqmel-qmnum.
        ls_entity-planningplant  = ls_viqmel-iwerk.
        ls_entity-locationid     = ls_viqmel-iloan.
        ls_entity-equipmentid    = ls_viqmel-equnr.
        ls_entity-plannergroup   = ls_viqmel-ingrp.

        " Date Safety Check (Prevents Null Crash)
        IF ls_viqmel-ausvn IS NOT INITIAL AND ls_viqmel-ausvn NE '00000000'.
          ls_entity-startdate = ls_viqmel-ausvn.
        ELSE.
          ls_entity-startdate = sy-datum. " Default to today if empty
        ENDIF.

        " Time Safety Check
        IF ls_viqmel-auztv IS NOT INITIAL.
           ls_entity-starttime = ls_viqmel-auztv.
        ELSE.
           ls_entity-starttime = '000000'.
        ENDIF.

        ls_entity-notiftype      = ls_viqmel-qmart.
        ls_entity-prioritytype   = ls_viqmel-artpr.
        ls_entity-description    = ls_viqmel-qmtxt.
        ls_entity-priority       = ls_viqmel-priok.
        ls_entity-workcenter     = ls_viqmel-arbpl.
        ls_entity-maintplant     = ls_viqmel-swerk.

        " Get Status Text (Safe Method using Middleman Variable)
        CLEAR lv_status_text.
        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
            objnr = ls_viqmel-objnr
            spras = sy-langu
          IMPORTING
            line  = lv_status_text
          EXCEPTIONS
            OTHERS = 1.

        " Copy result to entity
        ls_entity-statustext = lv_status_text.

        APPEND ls_entity TO et_entityset.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


METHOD plantlistset_get_entityset.
    DATA: lv_eng      TYPE zmaint_plant_863-maintenance_eng,
          ls_filter   TYPE /iwbep/s_mgw_select_option,
          ls_selopt   TYPE /iwbep/s_cod_select_option,
          lt_db_plant TYPE STANDARD TABLE OF zmaint_plant_863,
          ls_db_plant TYPE zmaint_plant_863,
          ls_t001w    TYPE t001w,
          ls_entity   TYPE zplantlist_s_863.

    " 1. Get Engineer ID from Filter
    " FIX: Check for 'Engineerid' (matches your Metadata)
    READ TABLE it_filter_select_options INTO ls_filter WITH KEY property = 'Engineerid'.

    IF sy-subrc = 0.
      READ TABLE ls_filter-select_options INTO ls_selopt INDEX 1.
      lv_eng = ls_selopt-low.

      " FIX: Add Leading Zeros (Turn '1' into '00000001')
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = lv_eng
        IMPORTING
          output = lv_eng.
    ENDIF.

    IF lv_eng IS NOT INITIAL.
      " 2. Get assigned plants from Z-Table
      SELECT * FROM zmaint_plant_863
        INTO TABLE lt_db_plant
        WHERE maintenance_eng = lv_eng.

      " 3. Loop and get details from T001W (Standard Plant Table)
      LOOP AT lt_db_plant INTO ls_db_plant.
        SELECT SINGLE * FROM t001w INTO ls_t001w WHERE werks = ls_db_plant-plant.

        IF sy-subrc = 0.
          " 4. Map DB fields to Friendly Names
          ls_entity-engineerid = ls_db_plant-maintenance_eng.
          ls_entity-plantid    = ls_t001w-werks.
          ls_entity-plantname  = ls_t001w-name1.
          ls_entity-street     = ls_t001w-stras.
          ls_entity-city       = ls_t001w-ort01.

          APPEND ls_entity TO et_entityset.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


METHOD workorderset_get_entityset.
    DATA: lv_sowrk       TYPE aufsowrk,
          lt_aufk        TYPE STANDARD TABLE OF aufk,
          ls_aufk        LIKE LINE OF lt_aufk,
          ls_entity      TYPE zworkorder_s_863,
          lv_top         TYPE i,
          lv_skip        TYPE i,
          lv_count       TYPE i,
          lv_status_text TYPE char40. " <--- FIX: Correct type

    " 1. Get Plant Filter (Matching Metadata Case Sensitivity)
    READ TABLE it_filter_select_options INTO DATA(ls_filter) WITH KEY property = 'Locationplant'.
    IF sy-subrc = 0.
      READ TABLE ls_filter-select_options INTO DATA(ls_selopt) INDEX 1.
      lv_sowrk = ls_selopt-low.
    ENDIF.

    " 2. Get Pagination (Compatibility Mode for older SAP versions)
    TRY.
        lv_top  = io_tech_request_context->get_top( ).
        lv_skip = io_tech_request_context->get_skip( ).
      CATCH cx_root.
        lv_top = 0.
        lv_skip = 0.
    ENDTRY.

    IF lv_sowrk IS NOT INITIAL.
      " 3. Select Data (Select All, Filter later)
      SELECT * FROM aufk
        INTO TABLE lt_aufk
        WHERE sowrk = lv_sowrk.

      " 4. Map Data and Apply Manual Paging
      lv_count = 0.

      LOOP AT lt_aufk INTO ls_aufk.
        lv_count = lv_count + 1.

        " Handle Skip (Offset)
        IF lv_skip > 0 AND lv_count <= lv_skip.
          CONTINUE.
        ENDIF.

        " Handle Top (Limit)
        IF lv_top > 0.
          DATA(lv_limit) = lv_skip + lv_top.
          IF lv_count > lv_limit.
            EXIT.
          ENDIF.
        ENDIF.

        " Map Data
        CLEAR ls_entity.
        ls_entity-orderid       = ls_aufk-aufnr.
        ls_entity-ordertype     = ls_aufk-auart.
        ls_entity-description   = ls_aufk-ktext.
        ls_entity-ordercategory = ls_aufk-autyp.
        ls_entity-companycode   = ls_aufk-bukrs.
        ls_entity-locationplant = ls_aufk-sowrk.
        ls_entity-plantid       = ls_aufk-werks.
        ls_entity-application   = ls_aufk-kappl.
        ls_entity-costingsheet  = ls_aufk-kalsm.
        ls_entity-workcenter    = ls_aufk-vaplz.
        ls_entity-costcenter    = ls_aufk-kostl.

        " Get Status Text (Safe Method using Middleman Variable)
        CLEAR lv_status_text.
        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
            objnr = ls_aufk-objnr
            spras = sy-langu
          IMPORTING
            line  = lv_status_text
          EXCEPTIONS
            OTHERS = 1.

        " Copy result to entity
        ls_entity-statustext = lv_status_text.

        APPEND ls_entity TO et_entityset.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
