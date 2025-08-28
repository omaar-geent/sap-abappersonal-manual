# ❌ Common ABAP Errors (detailed) – with explanation & fix

## 1) Row type ≠ SELECT list
**Example:**
```abap
DATA: lt_makt TYPE TABLE OF makt.
SELECT matnr maktx FROM makt INTO TABLE lt_makt.
❌ Why it’s wrong: row type expects all fields of MAKT; you only select 2 → mismatch.
✅ Fix: create a type with only matnr/maktx or use CORRESPONDING with a compatible structure.

2) FOR ALL ENTRIES with empty driver table
❌ If lt_keys IS INITIAL, the SELECT reads all DB records.
✅ Fix:

abap

IF lt_keys IS NOT INITIAL.
  SELECT ...
    FOR ALL ENTRIES IN lt_keys
    ...
ENDIF.
3) BINARY SEARCH without proper SORT
❌ Works only if the table is sorted by the exact same key (and order).
✅ Fix:

abap

SORT lt_tab BY k1 k2.
READ TABLE lt_tab WITH KEY k1 = lv_k1 k2 = lv_k2 BINARY SEARCH.
4) JOIN that multiplies rows (duplicates)
❌ A 1:N join generates more rows than expected.
✅ Fix: understand the cardinality; if you only need keys, use FOR ALL ENTRIES separately or DISTINCT in SQL.

5) SELECT inside LOOP (N+1 queries)
❌ Very slow.
✅ Fix: extract keys → use FOR ALL ENTRIES or a JOIN.

6) Forgetting SPRAS on MAKT
❌ Without language filter you may get wrong descriptions.
✅ Fix:

abap

WHERE spras = sy-langu.
7) INTO CORRESPONDING FIELDS OF TABLE with misaligned names
❌ If field names differ, fields remain empty.
✅ Fix: align field names or map manually.

8) Wrong key order in SORT
❌ Example: SORT lt BY matnr werks but later you READ with werks, matnr.
✅ Fix: sort by the same key order as the READ.

9) Not clearing the work area
❌ Reusing gs_out without CLEAR → values from previous row remain.
✅ Fix:

abap

CLEAR gs_out.
APPEND gs_out TO gt_out.
10) Using APPEND instead of COLLECT
❌ If you want aggregation per key, APPEND just duplicates rows.
✅ Fix: use COLLECT or aggregate with a hashed table.

11) Full table scan (no key condition)
❌ Without WHERE on keys → performance issues.
✅ Fix: always filter on indexed/key fields.

12) Nested LOOP O(n²)
❌ LOOP inside LOOP without indexes → very slow.
✅ Fix: use SORT + BINARY SEARCH or hashed tables.

13) SELECT * unnecessarily
❌ You fetch columns you don’t use.
✅ Fix: select only needed fields.

14) Missing sy-subrc check
❌ You don’t know if SELECT/READ found something.
✅ Fix:

abap

READ TABLE lt_tab WITH KEY ...
IF sy-subrc = 0.
  " Found
ENDIF.
