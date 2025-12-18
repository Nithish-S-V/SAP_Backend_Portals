class ZCL_ZSHOP_PORTAL_863_DPC_EXT definition
  public
  inheriting from ZCL_ZSHOP_PORTAL_863_DPC
  create public .

public section.
protected section.

  methods LOGINSET_CREATE_ENTITY
    redefinition .
  methods PLANNEDORDERSET_GET_ENTITYSET
    redefinition .
  methods PRODUCTIONORDERS_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSHOP_PORTAL_863_DPC_EXT IMPLEMENTATION.


method LOGINSET_CREATE_ENTITY.

  DATA: ls_login_input TYPE ZSHOPFLOORLOGIN_S_863, " Structure for incoming data
        ls_login_db    TYPE ZSHPFLLOGIN_T_86.    " Type to your transparent table structure

  " Read the data sent from the UI5 frontend (UserId and Password)
  io_data_provider->read_entry_data( IMPORTING es_data = ls_login_input ).

  " Validate login credentials against your custom transparent table
  SELECT SINGLE userid_863, password_863
    INTO (@ls_login_db-userid_863, @ls_login_db-password_863)
    FROM ZSHPFLLOGIN_T_86 " Your custom transparent table name
    WHERE userid_863 = @ls_login_input-userid    " OData property UserId
      AND password_863 = @ls_login_input-password. " OData property Password

  IF sy-subrc = 0.
    " If login is successful, return the validated user ID and password
    " ER_ENTITY is typed to ZSHOPFLOORLOGIN_S_863
    er_entity-userid   = ls_login_db-userid_863.
    er_entity-password = ls_login_db-password_863.
  ELSE.
    " Invalid login - Raise a business exception
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = |Invalid User ID or Password|.
  ENDIF.

endmethod.


method PLANNEDORDERSET_GET_ENTITYSET.

  DATA: lt_data       TYPE STANDARD TABLE OF ZSHOPFLOORPLANORDER_S_863, " Your OData entity structure
        ls_data       TYPE ZSHOPFLOORPLANORDER_S_863, " Work area for loop
        lt_plwrk_rng  TYPE RANGE OF plwrk,
        lt_psttr_rng  TYPE RANGE OF psttr,
        ls_filter     TYPE /iwbep/s_mgw_select_option,
        ls_selopt     TYPE /iwbep/s_cod_select_option.

  DATA: lv_sort_field  TYPE string,
        lv_sort_order  TYPE string.

  " Filters
  LOOP AT it_filter_select_options INTO ls_filter.
    CASE ls_filter-property.
      WHEN 'PlanningPlant'. " User-friendly OData property name for PLWRK
        LOOP AT ls_filter-select_options INTO ls_selopt.
          APPEND VALUE #( sign = ls_selopt-sign
                          option = ls_selopt-option
                          low = ls_selopt-low
                          high = ls_selopt-high ) TO lt_plwrk_rng.
        ENDLOOP.
      WHEN 'BasicStartDate'. " User-friendly OData property name for PSTTR
        LOOP AT ls_filter-select_options INTO ls_selopt.
          APPEND VALUE #( sign = ls_selopt-sign
                          option = ls_selopt-option
                          low = ls_selopt-low
                          high = ls_selopt-high ) TO lt_psttr_rng.
        ENDLOOP.
    ENDCASE.
  ENDLOOP.

  " Select data from PLAF
  " Ensure the fields in SELECT match the components of ZSHOPFLOORPLANORDER_S_863
  SELECT plnum AS PlannedOrderNumber,
         matnr AS MaterialNumber,
         plwrk AS PlanningPlant,
         pwwrk AS ProductionPlant,
         gsmng AS PlannedQuantity,
         avmng AS AvailableQuantity,
         psttr AS BasicStartDate,
         pedtr AS BasicEndDate,
         pertr AS ReleaseDate,
         dispo AS MRPController,
         paart AS OrderCategory,
         beskz AS ProcurementType,
         meins AS BaseUnitOfMeasure
    INTO CORRESPONDING FIELDS OF TABLE @lt_data
    FROM plaf
    WHERE plwrk IN @lt_plwrk_rng
      AND psttr IN @lt_psttr_rng.

  " --- NEW CODE TO HANDLE 00000000 DATES ---
  LOOP AT lt_data INTO ls_data.
    IF ls_data-BasicStartDate = '00000000'.
      ls_data-BasicStartDate = ''.
    ENDIF.
    IF ls_data-BasicEndDate = '00000000'.
      ls_data-BasicEndDate = ''.
    ENDIF.
    IF ls_data-ReleaseDate = '00000000'.
      ls_data-ReleaseDate = ''.
    ENDIF.
    MODIFY lt_data FROM ls_data.
  ENDLOOP.
  " --- END NEW CODE ---

  " Handle Sorting (only first sort field for simplicity)
  READ TABLE it_order INTO DATA(ls_order) INDEX 1.
  IF sy-subrc = 0 AND ls_order-property IS NOT INITIAL.
    lv_sort_field = ls_order-property.
    lv_sort_order = ls_order-order. " 'asc' or 'desc'

    CASE lv_sort_field.
      WHEN 'PlannedOrderNumber'.
        IF lv_sort_order = 'desc'.
          SORT lt_data BY PlannedOrderNumber DESCENDING.
        ELSE.
          SORT lt_data BY PlannedOrderNumber ASCENDING.
        ENDIF.
      WHEN 'MaterialNumber'.
        IF lv_sort_order = 'desc'.
          SORT lt_data BY MaterialNumber DESCENDING.
        ELSE.
          SORT lt_data BY MaterialNumber ASCENDING.
        ENDIF.
      WHEN 'BasicStartDate'.
        IF lv_sort_order = 'desc'.
          SORT lt_data BY BasicStartDate DESCENDING.
        ELSE.
          SORT lt_data BY BasicStartDate ASCENDING.
        ENDIF.
      WHEN 'BasicEndDate'.
        IF lv_sort_order = 'desc'.
          SORT lt_data BY BasicEndDate DESCENDING.
        ELSE.
          SORT lt_data BY BasicEndDate ASCENDING.
        ENDIF.
      " Add more fields here if needed for sorting
    ENDCASE.
  ENDIF.

  et_entityset = lt_data.

endmethod.


method PRODUCTIONORDERS_GET_ENTITYSET.
  DATA: lt_data    TYPE STANDARD TABLE OF ZSHOPFLOORPRODORDER_S_863, " Your OData entity structure
        ls_data    TYPE ZSHOPFLOORPRODORDER_S_863, " Work area for loop
        ls_filter  TYPE /iwbep/s_mgw_select_option,
        ls_selopt  TYPE /iwbep/s_cod_select_option,
        lv_werks   TYPE aufk-werks. " Still using standard type for internal filtering

  " Read the Plant filter from IT_FILTER_SELECT_OPTIONS
  LOOP AT it_filter_select_options INTO ls_filter.
    IF ls_filter-property = 'Plant'. " User-friendly OData property name for WERKS
      READ TABLE ls_filter-select_options INTO ls_selopt INDEX 1.
      IF sy-subrc = 0 AND ls_selopt-low IS NOT INITIAL.
        lv_werks = ls_selopt-low.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Join AUFK and AFKO
  IF lv_werks IS NOT INITIAL.
    SELECT a~aufnr AS OrderNumber,
           a~auart AS OrderType,
           a~werks AS Plant,
           a~ktext AS Description,
           a~ernam AS EnteredBy,
           a~erdat AS CreationDate,
           a~objnr AS ObjectNumber,
           b~gstrp AS BasicStartDate,
           b~gltrp AS BasicFinishDate,
           b~gamng AS TotalOrderQuantity,
           b~gmein AS BaseUnitOfMeasure,
           b~ftrmi AS ActualReleaseDate,
           b~ftrmp AS PlannedReleaseDate
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
      FROM aufk AS a
      INNER JOIN afko AS b ON a~aufnr = b~aufnr
      WHERE a~werks = @lv_werks.
  ELSE.
    SELECT a~aufnr AS OrderNumber,
           a~auart AS OrderType,
           a~werks AS Plant,
           a~ktext AS Description,
           a~ernam AS EnteredBy,
           a~erdat AS CreationDate,
           a~objnr AS ObjectNumber,
           b~gstrp AS BasicStartDate,
           b~gltrp AS BasicFinishDate,
           b~gamng AS TotalOrderQuantity,
           b~gmein AS BaseUnitOfMeasure,
           b~ftrmi AS ActualReleaseDate,
           b~ftrmp AS PlannedReleaseDate
      INTO CORRESPONDING FIELDS OF TABLE @lt_data
      FROM aufk AS a
      INNER JOIN afko AS b ON a~aufnr = b~aufnr.
  ENDIF.

  " --- NEW CODE TO HANDLE 00000000 DATES ---
  LOOP AT lt_data INTO ls_data.
    IF ls_data-CreationDate = '00000000'.
      ls_data-CreationDate = ''.
    ENDIF.
    IF ls_data-BasicStartDate = '00000000'.
      ls_data-BasicStartDate = ''.
    ENDIF.
    IF ls_data-BasicFinishDate = '00000000'.
      ls_data-BasicFinishDate = ''.
    ENDIF.
    IF ls_data-ActualReleaseDate = '00000000'.
      ls_data-ActualReleaseDate = ''.
    ENDIF.
    IF ls_data-PlannedReleaseDate = '00000000'.
      ls_data-PlannedReleaseDate = ''.
    ENDIF.
    MODIFY lt_data FROM ls_data.
  ENDLOOP.
  " --- END NEW CODE ---

  et_entityset = lt_data.

endmethod.
ENDCLASS.
