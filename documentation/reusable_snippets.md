# 🧩 Reusable ABAP Snippets

Each snippet explains **what it does** and **what you get**.

---

## (8.1) ALV Field Catalog Macro
**Purpose:** quickly create ALV columns.  
**Benefit:** less repetitive code, consistent texts.
```abap
DEFINE m_fcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = &1.
  gs_fieldcat-seltext_m = &2.
  APPEND gs_fieldcat TO gt_fieldcat.
END-OF-DEFINITION.
Safe FAE (driver not empty)

Purpose: read data in bulk for many keys.
Benefit: no SELECT inside LOOP, better performance.
IF lt_keys IS NOT INITIAL.
  SELECT col1 col2 FROM ztable INTO TABLE @DATA(lt_out)
    FOR ALL ENTRIES IN @lt_keys
    WHERE key = @lt_keys-key.
  SORT lt_out BY col1.
ENDIF.
Fast READ with BINARY SEARCH

Purpose: find a row in logarithmic time.
Benefit: very fast searches even with thousands of rows.
SORT lt_tab BY k1 k2.
READ TABLE lt_tab ASSIGNING FIELD-SYMBOL(<s>)
     WITH KEY k1 = lv_k1 k2 = lv_k2 BINARY SEARCH.
Build RANGES for WHERE IN

Purpose: pass multiple values to a SELECT.
Benefit: clean, reusable filters.
DATA: lr_vbeln TYPE RANGE OF vbak-vbeln.
APPEND VALUE #( sign = 'I' option = 'EQ' low = '0000123456' ) TO lr_vbeln.
Measure Performance

Purpose: compare two solutions with real numbers.
Benefit: choose the fastest approach based on data.
GET RUN TIME FIELD DATA(t1).
" ... code ...
GET RUN TIME FIELD DATA(t2).
WRITE: / 'µs:', t2 - t1.
 Field Catalog from DDIC Structure

Purpose: generate ALV field catalog from DDIC metadata.
Benefit: no naming/type errors
CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING i_structure_name = 'VBAK'
  CHANGING  ct_fieldcat      = gt_fieldcat.

Key-based Aggregation (no nested LOOP)

Purpose: sum values per key without O(n²).
Benefit: cleaner code and better performance.
TYPES: BEGIN OF ty_k,
  matnr TYPE mara-matnr,
  qty   TYPE lips-lfimg,
END OF ty_k.

DATA lt_aggr TYPE SORTED TABLE OF ty_k WITH UNIQUE KEY matnr.

LOOP AT lt_lips INTO DATA(s).
  READ TABLE lt_aggr ASSIGNING FIELD-SYMBOL(<a>)
    WITH KEY matnr = s-matnr BINARY SEARCH.
  IF sy-subrc = 0.
    <a>-qty = <a>-qty + s-lfimg.
  ELSE.
    INSERT VALUE ty_k( matnr = s-matnr qty = s-lfimg )
      INTO TABLE lt_aggr.
  ENDIF.
ENDLOOP.

Centralized Message Handling

Purpose: avoid spreading MESSAGE statements everywhere.
Benefit: simpler maintenance.
FORM msg USING p_text TYPE string.
  MESSAGE p_text TYPE 'S'.
ENDFORM.

Safe READ with Default Value

Purpose: avoid nested IF after READ.
Benefit: more linear code.
Safe READ with Default Value

Purpose: avoid nested IF after READ.
Benefit: more linear code.

Dynamic WHERE Builder

Purpose: build complex conditions without string concatenation.
Benefit: clarity on multiple filters.
DATA lr_kunnr TYPE RANGE OF vbak-kunnr.
APPEND VALUE #(
  sign = 'I' option = 'BT'
  low = '0000001000' high = '0000001999'
) TO lr_kunnr.

" ... then use: WHERE kunnr IN lr_kunnr
