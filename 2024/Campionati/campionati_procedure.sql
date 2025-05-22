-- questo file non contiene tutte le procedure sviluppate in aula
-- le procedure/funzioni elencate di seguito sono almeno quelle indispensabili per eseguire gli esempi Java su questo database

DROP PROCEDURE IF EXISTS formazione;
DROP PROCEDURE IF EXISTS squadra_appartenenza;
DROP FUNCTION IF EXISTS punti_in_partita;
DROP PROCEDURE IF EXISTS aggiungi_punti;
DROP FUNCTION IF EXISTS controlla_partita;
DROP FUNCTION IF EXISTS aggiorna_punti;

DELIMITER $

CREATE PROCEDURE formazione (idsquadra integer unsigned, anno smallint)
BEGIN
 SELECT f.numero, g.nome, g.cognome
  FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
  WHERE f.anno=anno AND f.ID_squadra=idsquadra
  ORDER BY f.numero asc;
END$

CREATE PROCEDURE squadra_appartenenza
(IN idgiocatore integer unsigned, IN anno smallint,
OUT nome_squadra varchar(100))
BEGIN
 SELECT s.nome
  FROM squadra s
   JOIN formazione f ON (f.ID_squadra=s.ID)
  WHERE f.ID_giocatore=idgiocatore AND f.anno=anno
 INTO nome_squadra;
END$

CREATE FUNCTION punti_in_partita(
idpartita integer unsigned, idsquadra integer unsigned)
  RETURNS integer DETERMINISTIC
BEGIN
 RETURN (SELECT sum(abs(e.punti))
  FROM segna e
   JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
   JOIN partita p ON (p.ID = e.ID_partita)
   JOIN campionato c ON (c.ID = p.ID_campionato)
  WHERE (f.anno = c.anno) AND (p.ID=idpartita)
 AND (f.ID_squadra=idsquadra));
END$

CREATE PROCEDURE aggiungi_punti( _ID_giocatore integer unsigned, 
 _ID_partita integer unsigned, _minuto smallint, _punti smallint)
BEGIN
 DECLARE IDsquadra_giocatore integer unsigned;
 DECLARE IDsquadra_1 integer unsigned;
 DECLARE IDsquadra_2 integer unsigned;

 SELECT f.ID_squadra
  FROM formazione f
  WHERE f.ID_giocatore=_ID_giocatore AND f.anno=(
   SELECT c.anno
    FROM campionato c JOIN partita p ON (c.ID=p.ID_campionato)
    WHERE p.ID=_ID_partita)
  INTO IDsquadra_giocatore;

 SELECT p.ID_squadra_1, p.ID_squadra_2
  FROM partita p
  WHERE p.ID=_ID_partita
 INTO IDsquadra_1,IDsquadra_2;

 IF (IDsquadra_giocatore=IDsquadra_1 OR IDsquadra_giocatore=IDsquadra_2) THEN
 BEGIN
  INSERT INTO segna(ID_giocatore,ID_partita,minuto,punti)
   VALUES (_ID_giocatore,_ID_partita,_minuto,_punti);

  UPDATE partita SET
   punti_squadra_1 = punti_squadra_1 +
    IF (_punti>0,
     IF(ID_squadra_1=IDsquadra_giocatore,_punti,0),
     IF(ID_squadra_2=IDsquadra_giocatore,-_punti,0)
    ),
   punti_squadra_2 = punti_squadra_2 +
    IF (_punti>0,
     IF(ID_squadra_2=IDsquadra_giocatore,_punti,0),
     IF(ID_squadra_1=IDsquadra_giocatore,-_punti,0)
    )     
   WHERE ID=_ID_partita;
 END;
 ELSE
 BEGIN
  SIGNAL SQLSTATE '45000'
  SET message_text="Il giocatore non è in partita";
 END;
 END IF;
END$

CREATE FUNCTION controlla_partita(idpartita integer unsigned) 
 RETURNS varchar(100) DETERMINISTIC
BEGIN
 DECLARE risultato varchar(100);
 DECLARE punti CURSOR FOR SELECT if(e.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva, 
  sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=idpartita AND f.anno=c.anno
 GROUP BY squadra_effettiva;
 
 SET risultato = "ok";
 OPEN punti;

 controlli: BEGIN
  DECLARE ids1 integer unsigned;
  DECLARE ids2 integer unsigned;
  DECLARE ps1 integer unsigned;
  DECLARE ps2 integer unsigned;
  DECLARE pcs1 integer unsigned;
  DECLARE pcs2 integer unsigned;
  SET pcs1=0;
  SET pcs2=0;
  SELECT ID_squadra_1,punti_squadra_1,ID_squadra_2,punti_squadra_2
   FROM partita
   WHERE ID=idpartita
  INTO ids1,ps1,ids2,ps2;

  ricalcolo: BEGIN
   DECLARE ids integer unsigned;
   DECLARE pcs integer unsigned;
   
   DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;

   LOOP
    FETCH punti INTO ids,pcs;
    IF (ids=ids1) THEN SET pcs1 = pcs;
    ELSEIF (ids=ids2) THEN SET pcs2 = pcs;
    ELSE BEGIN
     SET risultato = concat("La squadra ",(SELECT nome FROM squadra WHERE ID=ids),
	  " ha segnato ",pcs," punti ma non risulta in partita");
     LEAVE controlli;
     END;
    END IF;
   END LOOP;
  END;

    IF (ps1<>pcs1) THEN SET risultato = concat("I punti della squadra ",
   (SELECT nome FROM squadra WHERE ID=ids1),
   " sono ",pcs1," ma la tabella partita riporta ", ps1);
  ELSEIF (ps2<>pcs2) THEN SET risultato = concat("I punti della squadra ",
   (SELECT nome FROM squadra WHERE ID=ids2),
   " sono ",pcs2," ma la tabella partita riporta ", ps2);
  END IF;
 END;

 CLOSE punti; 
 RETURN risultato;
END$

CREATE PROCEDURE aggiorna_punti(idpartita integer unsigned)
BEGIN
 -- dati estratti dalla tabella partita
 DECLARE ids1 integer unsigned;
 DECLARE ids2 integer unsigned;
 -- punti calcolati dalla tabella segna
 DECLARE pcs1 integer unsigned;
 DECLARE pcs2 integer unsigned;
 -- query di calcolo del punteggio dalla tabella segna
 DECLARE punti CURSOR FOR SELECT if(e.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva, 
  sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=idpartita AND f.anno=c.anno
 GROUP BY squadra_effettiva;
  
 -- esecuzione query di ricalcolo
 OPEN punti;
 -- risultato di base (nel caso in cui una squadra non avesse segnato)
 SET pcs1=0;
 SET pcs2=0;
 -- informazioni presenti nella tabella partita
 SELECT ID_squadra_1,ID_squadra_2
  FROM partita
  WHERE ID=idpartita
 INTO ids1,ids2;
 
 -- blocco di ricalcolo
 BEGIN
 -- variabili temporanee locali al blocco
  DECLARE ids integer unsigned;
  DECLARE pcs integer unsigned;
 -- handler per il cursore (fa uscire dal blocco di ricalcolo)
  DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
 -- handler per l'errore (chiude il cursore e propaga la condizione)
  DECLARE EXIT HANDLER FOR SQLSTATE '45000'
  BEGIN
   CLOSE punti; -- chiudiamo il cursore
   RESIGNAL;
  END;
 -- loop di lettura dei punti (ri)calcolati dalla query
  LOOP
   FETCH punti INTO ids,pcs;
 -- aggiornamento dei punti ricalcolati in base alla squadra corrispondente
   IF (ids=ids1) THEN SET pcs1 = pcs;
   ELSEIF (ids=ids2) THEN SET pcs2 = pcs;
   ELSE BEGIN
 -- la squadra che ha segnato non è in partita!
    DECLARE messaggio varchar(100);
    SET messaggio = concat("La squadra ",(SELECT nome FROM squadra WHERE ID=ids),
	 " ha segnato ",pcs," punti ma non risulta in partita");
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = messaggio;
    END;
   END IF;
  END LOOP;
 END; -- ricalcolo
 
 CLOSE punti; -- chiudiamo il cursore
 -- aggiorniamo il punteggio della partita
 UPDATE partita
  SET punti_squadra_1=pcs1, punti_squadra_2=pcs2
  WHERE ID=idpartita;
END$

DELIMITER ;