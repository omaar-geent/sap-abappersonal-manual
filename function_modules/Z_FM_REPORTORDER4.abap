FUNCTION z_fm_reportorder4.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_VBELN) TYPE  VBELN_VA
*"     REFERENCE(I_KUNNR) TYPE  KUNAG OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_OUTPUT) TYPE  YCS_OUTPUT_T
*"----------------------------------------------------------------------

  DATA: lt_vbap   TYPE STANDARD TABLE OF vbap,
        lt_lips   TYPE STANDARD TABLE OF lips,
        lt_makt   TYPE STANDARD TABLE OF makt,
        ls_vbak   TYPE vbak,
        ls_vbap   TYPE vbap,
        ls_kna1   TYPE kna1,
        ls_lips   TYPE lips,
        ls_makt   TYPE makt,
        ls_output TYPE ycs_output_s,
        lv_lfimg  TYPE lips-lfimg,
        lv_kunnr  TYPE kunnr.          " <--- variabile per il cliente

  CLEAR e_output.

  " 1) Testata ordine
  SELECT SINGLE * FROM vbak INTO @ls_vbak WHERE vbeln = @i_vbeln.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 1.1) Decidi quale KUNNR usare:
  "     - se I_KUNNR passato: usa quello
  "     - altrimenti prendi da VBAK
  IF i_kunnr IS NOT INITIAL.
    lv_kunnr = i_kunnr.
  ELSE.
    lv_kunnr = ls_vbak-kunnr.
  ENDIF.


  " 2) Lettura anagrafica cliente solo se ho un KUNNR valorizzato
  CLEAR ls_kna1.
  IF lv_kunnr IS NOT INITIAL.
    SELECT SINGLE kunnr name1
      FROM kna1
      INTO CORRESPONDING FIELDS OF ls_kna1
      WHERE kunnr = lv_kunnr.
  ENDIF.

  " 3) Posizioni ordine
  SELECT * FROM vbap INTO TABLE @lt_vbap WHERE vbeln = @i_vbeln.
  IF lt_vbap IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_vbap BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM lt_vbap COMPARING vbeln posnr.

  " 4) LIPS + MAKT
  IF lt_vbap IS NOT INITIAL.
    SELECT * FROM lips INTO TABLE @lt_lips
      FOR ALL ENTRIES IN @lt_vbap
      WHERE vgbel = @lt_vbap-vbeln
        AND vgpos = @lt_vbap-posnr.
    SORT lt_lips BY vgbel vgpos.

    SELECT matnr, maktx FROM makt INTO TABLE @lt_makt
      FOR ALL ENTRIES IN @lt_vbap
      WHERE matnr = @lt_vbap-matnr
        AND spras = @sy-langu.
    SORT lt_makt BY matnr.
  ENDIF.

  " 5) Composizione output
  LOOP AT lt_vbap INTO ls_vbap.
    CLEAR: lv_lfimg, ls_output.

    " Somma LFIMG
    READ TABLE lt_lips TRANSPORTING NO FIELDS
         WITH KEY vgbel = ls_vbap-vbeln
                  vgpos = ls_vbap-posnr
         BINARY SEARCH.
    IF sy-subrc = 0.
      DATA(lv_idx) = sy-tabix.
      WHILE lv_idx <= lines( lt_lips ).
        READ TABLE lt_lips INTO ls_lips INDEX lv_idx.
        IF sy-subrc <> 0 OR
           ls_lips-vgbel <> ls_vbap-vbeln OR
           ls_lips-vgpos <> ls_vbap-posnr.
          EXIT.
        ENDIF.
        lv_lfimg = lv_lfimg + ls_lips-lfimg.
        lv_idx = lv_idx + 1.
      ENDWHILE.
    ENDIF.

    " Descrizione materiale
    READ TABLE lt_makt INTO ls_makt
         WITH KEY matnr = ls_vbap-matnr
         BINARY SEARCH.

    " Output
    ls_output-vbeln = ls_vbap-vbeln.
    ls_output-kunnr = lv_kunnr.           " <--- uso la variabile x kunnr opt
    ls_output-name1 = ls_kna1-name1.
    ls_output-erdat = ls_vbak-erdat.
    ls_output-posnr = ls_vbap-posnr.
    ls_output-matnr = ls_vbap-matnr.
    ls_output-arktx = ls_vbap-arktx.
    ls_output-zmeng = ls_vbap-zmeng.
    ls_output-meins = ls_vbap-meins.
    ls_output-lfimg = lv_lfimg.
    ls_output-maktx = ls_makt-maktx.

    IF ls_output-maktx IS INITIAL AND ls_output-arktx IS NOT INITIAL.
      ls_output-maktx = ls_output-arktx.
    ENDIF.

    APPEND ls_output TO e_output.
  ENDLOOP.

ENDFUNCTION.