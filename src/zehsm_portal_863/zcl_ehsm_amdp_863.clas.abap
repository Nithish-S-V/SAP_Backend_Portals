CLASS ZCL_EHSM_AMDP_863 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    " You can keep these local TYPES aliases for use within the implementation if preferred,
    " but for the method signatures below, we will use the global dictionary types directly.
    TYPES:
      tt_incidents TYPE zehsm_incident_863_t,
      tt_profile   TYPE zehsm_profile_863_t,
      tt_risks     TYPE zehsm_risk_863_t.

    CLASS-METHODS get_incidents
      IMPORTING
        VALUE(iv_client)    TYPE sy-mandt
        VALUE(iv_employeeid) TYPE persno
      EXPORTING
        VALUE(et_incidents)        TYPE zehsm_incident_863_t.

    CLASS-METHODS get_profile
      IMPORTING
        VALUE(iv_client)    TYPE sy-mandt
        VALUE(iv_employeeid) TYPE persno
      EXPORTING
        VALUE(et_profile)          TYPE zehsm_profile_863_t.   " <--- CHANGE: Use global table type directly

    CLASS-METHODS get_risks
      IMPORTING
        VALUE(iv_client)    TYPE sy-mandt
        VALUE(iv_employeeid) TYPE persno
      EXPORTING
        VALUE(et_risks)            TYPE zehsm_risk_863_t.       " <--- CHANGE: Use global table type directly

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS ZCL_EHSM_AMDP_863 IMPLEMENTATION.
 METHOD get_incidents BY DATABASE PROCEDURE
                        FOR HDB
                        LANGUAGE SQLSCRIPT
                        OPTIONS READ-ONLY
                        USING zinci_ehsm_dp pa0001.

    et_incidents =
      SELECT
        p.pernr             AS employee_id,
        i.incident_id       AS incident_id,
        i.plant             AS plant,
        i.incident_description AS incident_description,
        i.incident_category AS incident_category,
        i.incident_priority AS incident_priority,
        i.incident_status   AS incident_status,
        i.incident_date     AS incident_date,
        i.incident_time     AS incident_time,
        i.created_by        AS created_by,
        i.completion_date   AS completion_date,
        i.completion_time   AS completion_time
      FROM zinci_ehsm_dp AS i
      INNER JOIN pa0001  AS p
        ON  p.werks = i.plant
      WHERE p.mandt  = :iv_client
        AND p.pernr  = :iv_employeeid
        AND p.endda >= CURRENT_DATE
        AND p.begda <= CURRENT_DATE;

  ENDMETHOD.
  METHOD get_profile BY DATABASE PROCEDURE
                      FOR HDB
                      LANGUAGE SQLSCRIPT
                      OPTIONS READ-ONLY
                      USING pa0002 pa0001 pa0006 pa0105 pa0000.

    et_profile =
      SELECT
        a.pernr        AS employee_id,
        c.werks        AS plant,
        a.vorna        AS first_name,
        a.nachn        AS last_name,
        a.gesch        AS gender,
        d.usrid_long   AS email_id,
        a.sprsl        AS comm_language,
        a.natio        AS nationality,
        b.ort01        AS city,
        b.stras        AS street,
        b.land1        AS country,
        b.pstlz        AS postal_code,
        c.bukrs        AS company,
        e.stat2        AS employee_status,
        a.titel        AS title,
        c.begda        AS start_date
      FROM pa0002 AS a
      INNER JOIN pa0006 AS b
        ON  a.mandt = b.mandt
        AND a.pernr = b.pernr
      INNER JOIN pa0001 AS c
        ON  a.mandt = c.mandt
        AND a.pernr = c.pernr
      LEFT OUTER JOIN pa0105 AS d
        ON  a.mandt = d.mandt
        AND a.pernr = d.pernr
        AND d.subty = '0010'
      LEFT OUTER JOIN pa0000 AS e
        ON  a.mandt = e.mandt
        AND a.pernr = e.pernr
      WHERE a.mandt = :iv_client
        AND a.pernr = :iv_employeeid
        AND b.subty = '1'
        AND c.endda >= CURRENT_DATE
        AND c.begda <= CURRENT_DATE
        AND b.endda >= CURRENT_DATE
        AND b.begda <= CURRENT_DATE;

  ENDMETHOD.
  METHOD get_risks BY DATABASE PROCEDURE
                    FOR HDB
                    LANGUAGE SQLSCRIPT
                    OPTIONS READ-ONLY
                    USING zrisk_ehsm_dp pa0001.

    et_risks =
      SELECT
        p.pernr                    AS employee_id,
        r.risk_id                  AS risk_id,
        r.plant                    AS plant,
        r.risk_description         AS risk_description,
        r.risk_category            AS risk_category,
        r.risk_severity            AS risk_severity,
        r.mitigation_measures      AS mitigation_measures,
        r.likelihood               AS likelihood,
        r.created_by               AS created_by,
        r.risk_identification_date AS risk_identification_date
      FROM zrisk_ehsm_dp AS r
      INNER JOIN pa0001  AS p
        ON  p.werks = r.plant
      WHERE p.mandt  = :iv_client
        AND p.pernr  = :iv_employeeid
        AND p.endda >= CURRENT_DATE
        AND p.begda <= CURRENT_DATE;

  ENDMETHOD.

ENDCLASS.
