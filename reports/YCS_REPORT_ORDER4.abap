*&---------------------------------------------------------------------*
*& Report YCS_REPORT_ORDER4
*&---------------------------------------------------------------------*
REPORT YCS_REPORT_ORDER4.

INCLUDE ycs_report_order3_top.
INCLUDE ycs_report_order3_sel.

DATA: lt_output TYPE ti_output.

PERFORM extract_data CHANGING lt_output.

IF lt_output IS INITIAL.
  WRITE: / 'Nessun record da estrarre'.
  EXIT.
ELSE.
  PERFORM display_data USING lt_output.
ENDIF.

INCLUDE ycs_report_order3_form.




*&---------------------------------------------------------------------*
*&  Include           YCS_REPORT_ORDER3_TOP
*&---------------------------------------------------------------------*

" Tabelle principali
TABLES: vbak,
        vbap,
        kna1,
        lips,
        makt.

" Struttura header ordini
TYPES: BEGIN OF ty_vbak_short,
         vbeln TYPE vbak-vbeln,
         kunnr TYPE vbak-kunnr,
         erdat TYPE vbak-erdat,
       END OF ty_vbak_short.

" Struttura posizioni ordini
TYPES: BEGIN OF ty_vbap_short,
         vbeln TYPE vbap-vbeln,
         posnr TYPE vbap-posnr,
         matnr TYPE vbap-matnr,
         arktx TYPE vbap-arktx,
         zmeng TYPE vbap-zmeng,
       END OF ty_vbap_short.

" Struttura clienti
TYPES: BEGIN OF ty_kna1_str,
         kunnr TYPE kna1-kunnr,
         name1 TYPE kna1-name1,
       END OF ty_kna1_str.

" Riga LIPS
TYPES: BEGIN OF ty_lips_row,
         vbeln TYPE lips-vgbel,   " riferimento a documento precedente (ordine)
         posnr TYPE lips-vgpos,
         lfimg TYPE lips-lfimg,
       END OF ty_lips_row.

TYPES: BEGIN OF ty_lips_sum,
         vbeln TYPE lips-vgbel,
         posnr TYPE lips-vgpos,
         lfimg TYPE lips-lfimg,
       END OF ty_lips_sum.

" Struttura output finale
TYPES: BEGIN OF ty_output,
         vbeln TYPE vbak-vbeln,
         kunnr TYPE vbak-kunnr,
         name1 TYPE kna1-name1,
         erdat TYPE vbak-erdat,
         posnr TYPE vbap-posnr,
         matnr TYPE vbap-matnr,
         arktx TYPE vbap-arktx,
         zmeng TYPE vbap-zmeng,
         lfimg TYPE lips-lfimg,
         maktx TYPE makt-maktx,
       END OF ty_output.

TYPES: ti_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

  " Dichiarazioni locali
  DATA: lt_vbak   TYPE TABLE OF ty_vbak_short,  " Tabella ordini con VBELN+KUNNR
        ls_vbak   TYPE ty_vbak_short,           " Work area per singolo ordine
        lt_eoutput TYPE ycs_output_t,           " tabella restituita dal FM
        ls_eout    TYPE ycs_output_s,           " riga restituita dal FM
        ls_output  TYPE ty_output.              " riga dell'output finale del report

  DATA: it_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv.
		
		
		
		
		*&---------------------------------------------------------------------*
*&  Include           YCS_REPORT_ORDER3_SEL
*&---------------------------------------------------------------------*

" Selezione degli ordini in base ai criteri di ricerca


SELECT-OPTIONS: s_vbeln FOR vbak-vbeln,
                s_kunnr FOR vbak-kunnr,
                s_erdat FOR vbak-erdat.

" Gruppo di radiobutton: poi nel form extract data bisogna scrivere la logica
PARAMETERS: sortxord TYPE c RADIOBUTTON GROUP rad1 DEFAULT 'X',
            sortxclS  TYPE c RADIOBUTTON GROUP rad1.
			
			
			
			
			*&---------------------------------------------------------------------*
*&  Include           YCS_REPORT_ORDER3_FORM
*&---------------------------------------------------------------------*

FORM display_data USING pt_output TYPE ti_output.

  DEFINE append_fieldcat.
    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_m = &2.
    ls_fieldcat-col_pos   = &3.
    APPEND ls_fieldcat TO it_fieldcat.
  END-OF-DEFINITION.

  " Mostro sia ARKTX sia MAKTX (nessuna normalizzazione)
  append_fieldcat:
    'KUNNR' 'Codice cliente'         1,
    'NAME1' 'Ragione sociale'        2,
    'VBELN' 'Numero ordine'          3,
    'POSNR' 'Numero riga'            4,
    'MATNR' 'Codice materiale'       5,
    'ARKTX' 'Descrizione materiale'  6,
    'ZMENG' 'Quantità ordinata'      7,
    'LFIMG' 'Quantità spedita'       8,
    'MAKTX' 'Descr. materiale MAKT'  9.

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

*---------------------------------------------------------------------*
* Estrazione dati (versione che chiama il FM Z_FM_REPORTORDER4)
* Nessuna gestione duplicati ((non sono adiacenti e non si cancellano)), nessuna normalizzazione descrizioni
*---------------------------------------------------------------------*
FORM extract_data CHANGING lt_output TYPE ti_output.

  CLEAR lt_output.

  " 1) Seleziona la lista degli ordini reali in base ai filtri di selezione
  SELECT vbeln kunnr erdat
    FROM vbak
    INTO TABLE lt_vbak
    WHERE vbeln IN s_vbeln
      AND kunnr IN s_kunnr
      AND erdat IN s_erdat.

  IF lt_vbak IS INITIAL.
    " Nessun ordine trovato con i criteri selezionati
    RETURN.
  ENDIF.

  " Rimuovi eventuali duplicati e ordina per numero d'ordine
  SORT lt_vbak BY vbeln.
  DELETE ADJACENT DUPLICATES FROM lt_vbak COMPARING vbeln.

  " 2) Per ogni ordine, chiama il Function Module e accumula i risultati
  LOOP AT lt_vbak INTO ls_vbak.
    CLEAR lt_eoutput.

    " Chiamata al FM Z_FM_REPORTORDER4 con parametri ordine e cliente (MODIFICA)
    CALL FUNCTION 'Z_FM_REPORTORDER4'
      EXPORTING
        i_vbeln = ls_vbak-vbeln    " Numero ordine
        i_kunnr = ls_vbak-kunnr    " Codice cliente
      IMPORTING
        e_output = lt_eoutput
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      " Gestione errore; qui proseguiamo col prossimo ordine
      CONTINUE.
    ENDIF.

    IF lt_eoutput IS NOT INITIAL.
      " Trasferisci i campi dalla tabella restituita dal FM all'output del report
      LOOP AT lt_eoutput INTO ls_eout.
        CLEAR ls_output.
        MOVE-CORRESPONDING ls_eout TO ls_output.
        APPEND ls_output TO lt_output.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
"qua faccio gli ordinamenti per i casi della checkbox
    IF sortxord = 'X'.
    SORT lt_output BY vbeln posnr.         " Ordina per ordine
  ELSEIF sortxcls = 'X'.
    SORT lt_output BY kunnr vbeln posnr.   " Ordina per cliente -> ordine
  ENDIF.


ENDFORM.