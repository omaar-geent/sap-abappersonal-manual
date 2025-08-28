ERRORI COMUNI (molto dettagliato) – con spiegazione & fix
1)	Tipo riga ≠ lista SELECT
Esempio: lt_makt TYPE TABLE OF makt ma fai SELECT matnr maktx FROM makt INTO TABLE lt_makt.
Perché NON va: il tipo riga si aspetta tutti i campi di MAKT; tu ne dai solo 2 → mismatch.
Fix: crea un tipo con solo matnr/maktx oppure usa CORRESPONDING con struttura compatibile.
2)	FOR ALL ENTRIES con tabella driver vuota
Se lt_keys IS INITIAL, la SELECT legge tutto.
Fix: IF lt_keys IS NOT INITIAL. SELECT ... ENDIF.
3)	BINARY SEARCH senza SORT coerente
Funziona solo se la tabella è ordinata per quella stessa chiave (e ordine).
Fix: SORT lt_tab BY k1 k2. Poi READ ... WITH KEY k1 = ... k2 = ... BINARY SEARCH.
4)	JOIN che moltiplica righe (duplicati)
Un JOIN 1:N genera più righe del previsto.
Fix: capisci la cardinalità; se ti servono solo le chiavi, usa FAE separati o DISTINCT lato DB.
5)	SELECT dentro LOOP (N+1 query)
Fix: estrai chiavi → usa FAE o JOIN.
6)	Dimenticare SPRAS su MAKT
Senza lingua potresti leggere descrizioni sbagliate.
Fix: WHERE spras = sy-langu.
7)	INTO CORRESPONDING FIELDS OF TABLE con nomi non allineati
Se i nomi campo differiscono, i campi restano vuoti.
Fix: allinea i nomi o mappa manualmente.
8)	Chiave multipla in ordine sbagliato
SORT lt BY matnr werks ma cerchi werks, matnr → non funziona.
Fix: stesso ordine tra SORT e READ.
9)	Non svuotare work area
Riusi gs_out senza CLEAR → valori della riga precedente.
Fix: CLEAR gs_out prima di ogni nuovo APPEND.
10)	Usare APPEND quando serviva COLLECT
Se vuoi aggregare per chiave, COLLECT somma le quantità per la stessa chiave.
Fix: usa COLLECT o aggrega tu con hashed table.
11)	Full scan per mancanza di condizione-chiave
Senza WHERE su chiavi → lentezza.
Fix: filtra sempre su campi indicizzati/chiave.
12)	Nested LOOP O(n²)
LOOP in LOOP senza indici → lento.
Fix: SORT + BINARY SEARCH o HASHED TABLE.
13)	SELECT * inutile
Porti a casa colonne che non usi.
Fix: seleziona solo i campi necessari.
14)	Mancato controllo sy-subrc
Non sai se hai trovato qualcosa.
Fix: controllalo sempre dopo READ/SELECT.
