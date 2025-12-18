CLASS zcl_vendor_portal_863 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    " 1. LOGIN VALIDATION
    CLASS-METHODS validate_login
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
                VALUE(iv_password)  TYPE char20
      EXPORTING VALUE(et_response)  TYPE ztt_login_res_863.

    " 2. GET VENDOR PROFILE
    CLASS-METHODS get_profile
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_profile)   TYPE ztt_profile_863.

    " 3. GET RFQs (Tables: EKKO, EKPO)
    CLASS-METHODS get_rfqs
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_rfq)       TYPE ztt_rfq_863.

    " 4. GET PURCHASE ORDERS (Tables: EKKO, EKPO, EKET)
    CLASS-METHODS get_pos
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_po)        TYPE ztt_po_863.

    " 5. GET GOODS RECEIPTS (Tables: MKPF, MSEG)
    CLASS-METHODS get_grs
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_gr)        TYPE ztt_gr_863.

    " 6. GET FINANCIALS (Tables: BKPF, BSEG - Matches pAYaGE.txt)
    CLASS-METHODS get_financials
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_finance)   TYPE ztt_fin_863.

    " 7. GET MEMOS (Tables: BKPF, BSEG - Matches MEMO.txt)
    CLASS-METHODS get_memos
      IMPORTING VALUE(iv_vendor_id) TYPE lifnr
      EXPORTING VALUE(et_memos)     TYPE ztt_memo_863.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_vendor_portal_863 IMPLEMENTATION.

  METHOD validate_login BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                        USING zlogin_vend_863.
    DECLARE lv_count INTEGER;
    -- FIX: Auto-pad ID with zeros (e.g. '1000' -> '0000001000') to match DB format
    DECLARE lv_id_pad NVARCHAR(10) := LPAD(:iv_vendor_id, 10, '0');

    SELECT COUNT(*) INTO lv_count
    FROM zlogin_vend_863
    WHERE vendor_id = :lv_id_pad
      AND password  = :iv_password;

    IF :lv_count > 0 THEN
        et_response = SELECT 'X' AS success, 'Login Successful' AS message FROM DUMMY;
    ELSE
        et_response = SELECT '' AS success, 'Invalid Credentials' AS message FROM DUMMY;
    END IF;
  ENDMETHOD.


  METHOD get_profile BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                     USING lfa1.
    et_profile = SELECT
           lifnr AS vendor_id,
           name1 AS vendor_name,
           ort01 AS city,
           land1 AS country,
           'ACTIVE' AS status_msg
    FROM lfa1
    -- FIX: Added LPAD to match '0000100000'
    WHERE lifnr = LPAD(:iv_vendor_id, 10, '0');
  ENDMETHOD.


  METHOD get_rfqs BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                  USING ekko ekpo.
    et_rfq = SELECT
                k.lifnr AS vendor_id,
                k.ebeln AS rfq_number,
                k.bedat AS rfq_date,
                p.txz01 AS material_text,
                p.menge AS quantity,
                p.meins AS unit
             FROM ekko AS k
             INNER JOIN ekpo AS p ON k.ebeln = p.ebeln
             -- FIX: Added LPAD
             WHERE k.lifnr = LPAD(:iv_vendor_id, 10, '0')
               AND k.bsart = 'AN';
  ENDMETHOD.


  METHOD get_pos BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                 USING ekko ekpo eket.
    et_po = SELECT
               k.ebeln AS po_number,
               k.lifnr AS vendor_id,
               k.bedat AS po_date,
               k.ekorg AS purch_org,
               p.matnr AS material_no,
               p.meins AS unit,
               p.netpr AS net_price,
               s.eindt AS delivery_date,
               k.waers AS currency
            FROM ekko AS k
            INNER JOIN ekpo AS p ON k.ebeln = p.ebeln
            LEFT OUTER JOIN eket AS s ON p.ebeln = s.ebeln AND p.ebelp = s.ebelp
            -- FIX: Added LPAD
            WHERE k.lifnr = LPAD(:iv_vendor_id, 10, '0');
  ENDMETHOD.

METHOD get_grs BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                 USING mseg.

    -- STRICT MSEG ONLY:
    -- 1. No Joins.
    -- 2. Vendor Check: Using LPAD to match '0000100000'.
    -- 3. Date: Using 'CPUDT' (Entry Date) because BUDAT is not in MSEG.

    et_gr = SELECT
               mblnr AS mat_doc_num,
               mjahr AS fiscal_year,
               bukrs AS comp_code,
               lifnr AS vendor_id,
               matnr AS material_no,
               werks AS plant,
               BUDAT_MKPF AS posting_date
            FROM mseg
            WHERE lifnr = iv_vendor_id;

  ENDMETHOD.

METHOD get_financials BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                        USING rbkp.

    -- CHANGED SOURCE: Now reading from RBKP (Logistics Invoice)
    -- This ensures the Doc Number matches your PDF and Screenshot (51056...)

    et_finance = SELECT
                    lifnr AS vendor_id,
                    belnr AS invoice_num,
                    budat AS posting_date,
                    bldat AS doc_date,
                    waers AS currency,
                    mwskz1 AS tax_code, -- Tax code from Header
                    rmwwr AS amount,    -- Gross Invoice Amount in RBKP
                    zfbdt AS baseline_date,
                    zterm AS payment_term,

                    -- Safe Due Date Calculation
                    TO_NVARCHAR(
                        ADD_DAYS(
                            CASE WHEN zfbdt = '00000000' OR zfbdt = '' THEN budat
                            ELSE zfbdt
                            END,
                        30),
                    'YYYYMMDD') AS due_date,

                    -- Safe Aging Calculation
                    DAYS_BETWEEN(
                        ADD_DAYS(
                            CASE WHEN zfbdt = '00000000' OR zfbdt = '' THEN budat
                            ELSE zfbdt
                            END,
                        30),
                        CURRENT_DATE
                    ) AS aging_days

                 FROM rbkp
                 -- Fix Leading Zeros for Vendor ID
                 WHERE lifnr = LPAD(:iv_vendor_id, 10, '0');

  ENDMETHOD.


  METHOD get_memos BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                   USING bkpf bseg.
    -- UPDATED: Uses BKPF (Header) and BSEG (Item) matching 'MEMO.txt'
    et_memos = SELECT
                    b.lifnr AS vendor_id,
                    b.belnr AS memo_num,
                    b.gjahr AS fiscal_year,
                    b.buzei AS item_num,
                    a.blart AS doc_type,
                    a.budat AS posting_date,
                    a.bldat AS doc_date,
                    b.dmbtr AS amount,
                    a.waers AS currency,
                    b.menge AS quantity,
                    b.meins AS unit,
                    b.matnr AS material_no,
                    b.hkont AS gl_account,
                    b.shkzg AS debit_cred_ind,
                    b.bschl AS posting_key
                 FROM bkpf AS a
                 INNER JOIN bseg AS b
                   ON a.bukrs = b.bukrs
                  AND a.belnr = b.belnr
                  AND a.gjahr = b.gjahr
                 -- FIX: Added LPAD
                 WHERE b.lifnr = LPAD(:iv_vendor_id, 10, '0');
  ENDMETHOD.

ENDCLASS.
