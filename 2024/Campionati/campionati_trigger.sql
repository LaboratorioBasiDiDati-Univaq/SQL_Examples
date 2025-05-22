-- questo file non contiene tutti i trigger sviluppati in aula
-- poichè i dati presenti nel file di creazione di questo database contengono volontariamente degli errori
-- è indispensabile creare i trigger solo dopo aver popolato il database

DROP TRIGGER IF EXISTS giocatore_valido;
DROP TRIGGER IF EXISTS data_partita_valida_i;
DROP TRIGGER IF EXISTS data_partita_valida_u;
DROP TRIGGER IF EXISTS aggiorna_punti_i;
DROP TRIGGER IF EXISTS aggiorna_punti_u;
DROP TRIGGER IF EXISTS aggiorna_punti_d;
DROP PROCEDURE IF EXISTS convalida_data;
DROP PROCEDURE IF EXISTS step_punti;


DELIMITER $

CREATE TRIGGER giocatore_valido BEFORE INSERT ON segna
FOR EACH ROW BEGIN
  IF NEW.ID_giocatore NOT IN (
  SELECT ID_giocatore
   FROM partita p
    JOIN campionato c ON (p.ID_campionato=c.ID)
    JOIN formazione f ON (f.anno=c.anno AND (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2))
   WHERE p.ID=NEW.ID_partita)
 THEN
  SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT="Il giocatore non è in partita";
 END IF;
END$

CREATE PROCEDURE convalida_data
(idcampionato integer unsigned, data datetime)
BEGIN
 DECLARE a smallint;
 SELECT anno FROM campionato WHERE ID =idcampionato INTO a;
 IF data NOT BETWEEN str_to_date(concat(a,"-09-01"),"%Y-%m-%d")
  AND str_to_date(concat((a+1),"-06-30"),"%Y-%m-%d")
  THEN BEGIN
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = "Data non inclusa nel campionato";
  END;
 END IF;
END$

CREATE TRIGGER data_partita_valida_i BEFORE INSERT ON
partita
FOR EACH ROW BEGIN
 CALL convalida_data(NEW.ID_campionato,NEW.data);
END$

CREATE TRIGGER data_partita_valida_u BEFORE UPDATE ON partita
FOR EACH ROW BEGIN
 CALL convalida_data(NEW.ID_campionato,NEW.data);
END$

CREATE PROCEDURE step_punti (idpartita integer unsigned,
idgiocatore integer unsigned, step smallint, auto tinyint)
BEGIN
 DECLARE s integer unsigned;
 
 SELECT if(auto<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva
  FROM formazione f 
   JOIN partita p  
   JOIN campionato c ON (c.ID = p.ID_campionato)
  WHERE p.ID=idpartita AND (f.anno=c.anno AND f.ID_giocatore=idgiocatore)
 INTO s;
  
 UPDATE partita
  SET punti_squadra_1=greatest(0,cast(punti_squadra_1 AS SIGNED)+IF(s=ID_squadra_1,step,0)),
      punti_squadra_2=greatest(0,cast(punti_squadra_2 AS SIGNED)+IF(s=ID_squadra_2,step,0))
  WHERE ID=idpartita;
END$  

CREATE TRIGGER aggiorna_punti_i AFTER INSERT ON segna
FOR EACH ROW BEGIN
 CALL step_punti(NEW.ID_partita,NEW.ID_giocatore,abs(NEW.punti),sign(NEW.punti));
END$


CREATE TRIGGER aggiorna_punti_d AFTER DELETE ON segna
FOR EACH ROW BEGIN
 CALL step_punti(OLD.ID_partita,OLD.ID_giocatore,-abs(OLD.punti),sign(OLD.punti));
END$


CREATE TRIGGER aggiorna_punti_u AFTER UPDATE ON segna
FOR EACH ROW BEGIN
 CALL step_punti(OLD.ID_partita,OLD.ID_giocatore,-abs(OLD.punti),sign(OLD.punti));
 CALL step_punti(NEW.ID_partita,NEW.ID_giocatore,abs(NEW.punti),sign(NEW.punti));
END$




DELIMITER ;