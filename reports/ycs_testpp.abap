*&---------------------------------------------------------------------*
*& Report YCS_TESTPP
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ycs_testpp.

INCLUDE ycs_testpp_top.
INCLUDE ycs_testpp_sel.

DATA: lt_output TYPE ti_output.

START-OF-SELECTION.
  PERFORM extract_data CHANGING lt_output.

  IF lt_output IS INITIAL.
    WRITE: / 'Nessun record trovato'.
  ELSE.
    PERFORM display_data USING lt_output.
  ENDIF.

INCLUDE ycs_testpp_form.




*&---------------------------------------------------------------------*
*&  Include           YCS_TESTPP_TOP
*&---------------------------------------------------------------------*
" Tabelle principali
TABLES: aufk,
        afko,
        afvc,
        resb,
        makt.

" Strutture output finale
TYPES: BEGIN OF ty_output,
         aufnr  TYPE aufk-aufnr,
         werks  TYPE aufk-werks,
         plnbez TYPE afko-plnbez,
         zgrid  TYPE aufk-zgridvalue,
         maktxp TYPE makt-maktx,      " descrizione prodotto
         gamng  TYPE afko-gamng,
         gltrs  TYPE afko-gltrs,
         vornr  TYPE afvc-vornr,
         ktsch  TYPE afvc-ktsch,
         ltxa1  TYPE afvc-ltxa1,
         matnr  TYPE resb-matnr,
         maktxc TYPE makt-maktx,      " descrizione componente
         bdmng  TYPE resb-bdmng,
         lgort  TYPE resb-lgort,
       END OF ty_output.

TYPES: ti_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

" Tabelle interne di appoggio
DATA: lt_aufk TYPE STANDARD TABLE OF aufk,
      lt_afko TYPE STANDARD TABLE OF afko,
      lt_afvc TYPE STANDARD TABLE OF afvc,
      lt_resb TYPE STANDARD TABLE OF resb,
      lt_makt TYPE STANDARD TABLE OF makt.
	  
	  
	  
	  
	  *&---------------------------------------------------------------------*
*&  Include           YCS_TESTPP_SEL
*&---------------------------------------------------------------------*
"selezione
SELECT-OPTIONS: s_aufnr FOR aufk-aufnr.




*&---------------------------------------------------------------------*
*&  Include           YCS_TESTPP_FORM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_OUTPUT  text
*----------------------------------------------------------------------*
FORM display_data USING pt_output TYPE ti_output.

  DATA: it_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv.

  DEFINE append_fieldcat.
    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_m = &2.
    ls_fieldcat-col_pos   = &3.
    APPEND ls_fieldcat TO it_fieldcat.
  END-OF-DEFINITION.

  append_fieldcat:
    'AUFNR'  'Ordine Prod.'        1,
    'WERKS'  'Stabilimento'        2,
    'ZGRID'  'ZGridValue'          3,
    'PLNBEZ' 'Materiale Padre'     4,
    'MAKTXP' 'Descr. Materiale'    5,
    'GAMNG'  'Quantità Ordine'     6,
    'GLTRS'  'Data Fine'           7,
    'VORNR'  'Operazione'          8,
    'KTSCH'  'Chiave Controllo'    9,
    'LTXA1'  'Descr. Operazione'  10,
    'MATNR'  'Componente'         11,
    'MAKTXC' 'Descr. Componente'  12,
    'BDMNG'  'Qta Comp.'          13,
    'LGORT'  'Magazzino'          14.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat        = it_fieldcat
      i_callback_program = sy-repid
    TABLES
      t_outtab           = pt_output
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Errore nella visualizzazione ALV' TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  EXTRACT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_OUTPUT  text
*----------------------------------------------------------------------*
FORM extract_data CHANGING lt_output TYPE ti_output.

  DATA: ls_output           TYPE ty_output,
        ls_makt_prod        TYPE makt,
        ls_makt_comp        TYPE makt,
        lv_component_found  TYPE abap_bool.

  " Field-symbols dichiarati UNA SOLA VOLTA
  FIELD-SYMBOLS: <fs_aufk> TYPE aufk,
                 <fs_afko> TYPE afko,
                 <fs_afvc> TYPE afvc,
                 <fs_resb> TYPE resb.

  CLEAR lt_output.

  " 1) AUFK
  SELECT * FROM aufk
    INTO TABLE lt_aufk
    WHERE aufnr IN s_aufnr.

  IF lt_aufk IS INITIAL.
    RETURN.
  ENDIF.

  " 2) AFKO
  SELECT * FROM afko
    INTO TABLE lt_afko
    FOR ALL ENTRIES IN lt_aufk  "Prendo le testate di produzione corrispondenti agli ordini trovati.
    WHERE aufnr = lt_aufk-aufnr.

  " 3) AFVC
  SELECT * FROM afvc
    INTO TABLE lt_afvc
    FOR ALL ENTRIES IN lt_afko
    WHERE aufpl = lt_afko-aufpl. "Ogni ordine ha una sequenza di operazioni (identificata da AUFPL).
  SORT lt_afvc BY aufpl vornr.

  " 4) RESB
  SELECT * FROM resb
    INTO TABLE lt_resb
    FOR ALL ENTRIES IN lt_afko
    WHERE rsnum = lt_afko-rsnum.
  SORT lt_resb BY rsnum vornr.

 " 5) MAKT (descrizioni per padre + componenti)
DATA: lt_matnr TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.

LOOP AT lt_afko ASSIGNING <fs_afko>.
  INSERT <fs_afko>-plnbez INTO TABLE lt_matnr.
ENDLOOP.

LOOP AT lt_resb ASSIGNING <fs_resb>.
  IF <fs_resb>-matnr IS NOT INITIAL.
    INSERT <fs_resb>-matnr INTO TABLE lt_matnr.
  ENDIF.
ENDLOOP.

IF lt_matnr IS NOT INITIAL.
  " allinea tipo riga = MAKT selezionando *
  SELECT *
    FROM makt
    INTO TABLE lt_makt
    FOR ALL ENTRIES IN lt_matnr
    WHERE matnr = lt_matnr-table_line
      AND spras = sy-langu.

  SORT lt_makt BY matnr.  " unica lingua => OK BINARY SEARCH su MATNR
ENDIF.


  " 6) Costruzione output
  LOOP AT lt_aufk ASSIGNING <fs_aufk>.

    " prendo l'AFKO dell'ordine
    READ TABLE lt_afko ASSIGNING <fs_afko>
         WITH KEY aufnr = <fs_aufk>-aufnr.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    " scorro le operazioni dell'ordine (per AUFPL)
    LOOP AT lt_afvc ASSIGNING <fs_afvc>
         WHERE aufpl = <fs_afko>-aufpl.

      lv_component_found = abap_false.

      " scorro i componenti della specifica operazione (RSNUM+VORNR)
      LOOP AT lt_resb ASSIGNING <fs_resb>
           WHERE rsnum = <fs_afko>-rsnum
             AND vornr = <fs_afvc>-vornr.

        CLEAR: ls_output, ls_makt_prod, ls_makt_comp.

        " Testata
        ls_output-aufnr  = <fs_aufk>-aufnr.
        ls_output-werks  = <fs_aufk>-werks.
        ls_output-zgrid  = <fs_aufk>-zgridvalue.
        ls_output-plnbez = <fs_afko>-plnbez.
        READ TABLE lt_makt INTO ls_makt_prod
             WITH KEY matnr = <fs_afko>-plnbez BINARY SEARCH.
        ls_output-maktxp = ls_makt_prod-maktx.
        ls_output-gamng  = <fs_afko>-gamng.
        ls_output-gltrs  = <fs_afko>-gltrs.

        " Operazione
        ls_output-vornr  = <fs_afvc>-vornr.
        ls_output-ktsch  = <fs_afvc>-ktsch.
        ls_output-ltxa1  = <fs_afvc>-ltxa1.

        " Componente
        ls_output-matnr  = <fs_resb>-matnr.
        ls_output-bdmng  = <fs_resb>-bdmng.
        ls_output-lgort  = <fs_resb>-lgort.
        READ TABLE lt_makt INTO ls_makt_comp
             WITH KEY matnr = <fs_resb>-matnr BINARY SEARCH.
        ls_output-maktxc = ls_makt_comp-maktx.

        APPEND ls_output TO lt_output.
        lv_component_found = abap_true.

      ENDLOOP.

      " Operazione senza componenti: riga con campi componente vuoti
      IF lv_component_found = abap_false.
        CLEAR: ls_output, ls_makt_prod.
        ls_output-aufnr  = <fs_aufk>-aufnr.
        ls_output-werks  = <fs_aufk>-werks.
        ls_output-zgrid  = <fs_aufk>-zgridvalue.
        ls_output-plnbez = <fs_afko>-plnbez.
        READ TABLE lt_makt INTO ls_makt_prod
             WITH KEY matnr = <fs_afko>-plnbez BINARY SEARCH.
        ls_output-maktxp = ls_makt_prod-maktx.
        ls_output-gamng  = <fs_afko>-gamng.
        ls_output-gltrs  = <fs_afko>-gltrs.
        ls_output-vornr  = <fs_afvc>-vornr.
        ls_output-ktsch  = <fs_afvc>-ktsch.
        ls_output-ltxa1  = <fs_afvc>-ltxa1.

        APPEND ls_output TO lt_output.
      ENDIF.

    ENDLOOP.
  ENDLOOP.

  SORT lt_output BY aufnr vornr.

ENDFORM.