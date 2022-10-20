-- selezioniamo il database di default per tutte le istruzioni successive
USE campionati;

-- svuotiamo le tabelle
DELETE FROM partita;
DELETE FROM formazione;
DELETE FROM direzione;
DELETE FROM squadra;
DELETE FROM segna;
DELETE FROM giocatore;
DELETE FROM campionato;
DELETE FROM arbitro;
DELETE FROM luogo;

INSERT INTO `campionato` 
-- dobbiamo specificare tutti i campi, nell'ordine di creazione
VALUES(1,"campionato di calcio serie A",2020);

-- possiamo omettere i campi auto_increment o quelli con default
INSERT INTO `campionato`(anno,nome) 
VALUES(2020,"campionato di calcio serie B");

INSERT INTO `arbitro`
(`CF`,`nome`,`cognome`)
VALUES ("1234567890123456","Pinco","Arbitro");

-- di seguito inseriremo sempre esplicitamente tutte chiavi
-- per essere sicuri delle chiavi da usare con le relazioni
INSERT INTO `giocatore`
(`ID`,`nome`,`cognome`,`dataNascita`,`luogoNascita`)
VALUES (1,"Pallino1","Giocatore","2020-04-21","Roma");

INSERT INTO `giocatore`
(`ID`,`nome`,`cognome`,`dataNascita`,`luogoNascita`)
VALUES (2,"Pallino2","Giocatore","2020-04-22","Milano");

INSERT INTO `giocatore`
(`ID`,`nome`,`cognome`,`dataNascita`,`luogoNascita`)
VALUES (3,"Pallino3","Giocatore","2020-04-23","Palermo");

INSERT INTO `giocatore`
(`ID`,`nome`,`cognome`,`dataNascita`,`luogoNascita`)
VALUES (4,"Solitario","Giocatore","2020-05-06","L'Aquila");

INSERT INTO `squadra`
(`ID`,`nome`,`citta`)
VALUES (1,"L'Aquila Calcio", "L'Aquila");

INSERT INTO `squadra` 
(`ID`,`nome`, `citta`) 
VALUES (2,'Paperopoli Calcio', 'Paperopoli');

INSERT INTO `squadra` 
(`ID`,`nome`, `citta`) 
VALUES (3,'Topolinia Calcio', 'Topolinia');

INSERT INTO `luogo`
(`ID`,`nome`,`citta`)
VALUES (1,"Stadio Comunale","L'Aquila");

INSERT INTO `luogo`
(`ID`,`nome`,`citta`)
VALUES (2,"Stadio Olimpico","Roma");

INSERT INTO `luogo`
(`ID`,`nome`,`citta`)
VALUES (3,"Altro Stadio","L'Aquila");

INSERT INTO `formazione`
(`ID_giocatore`,`ID_squadra`,`anno`,`numero`)
VALUES (1,1,2020,10);

INSERT INTO `formazione`
(`ID_giocatore`,`ID_squadra`,`anno`,`numero`)
VALUES (2,1,2020,5);

INSERT INTO `formazione`
(`ID_giocatore`,`ID_squadra`,`anno`,`numero`)
VALUES (2,1,2019,5);

INSERT INTO `formazione`
(`ID_giocatore`,`ID_squadra`,`anno`,`numero`)
VALUES (3,2,2020,4);

INSERT INTO `formazione`
(`ID_giocatore`,`ID_squadra`,`anno`,`numero`)
VALUES (1,2,2019,40);

INSERT INTO `partita`
(`ID`,`data`,`ID_campionato`,`ID_luogo`,`ID_squadra_1`,`ID_squadra_2`,`punti_squadra_1`,`punti_squadra_2`)
VALUES (1,"2020-09-24 16:30:00",1,1,1,2,2,1);

-- omettiamo i punti, quindi il risultato sarà impostato su 0-0
INSERT INTO `partita`
(`ID`,`data`,`ID_campionato`,`ID_luogo`,`ID_squadra_1`,`ID_squadra_2`)
VALUES (2,"2020-09-22 12:00:00",1,1,2,1);

INSERT INTO `partita`
(`ID`,`data`,`ID_campionato`,`ID_luogo`,`ID_squadra_1`,`ID_squadra_2`,`punti_squadra_1`,`punti_squadra_2`)
VALUES (3,"2021-01-20 16:30:00",1,2,1,2,0,10);

INSERT INTO `segna`
(`ID_giocatore`,`ID_partita`,`minuto`)
VALUES (1,1,15);

INSERT INTO `segna`
(`ID_giocatore`,`ID_partita`,`minuto`)
VALUES (2,1,12);

INSERT INTO `segna`
(`ID_giocatore`,`ID_partita`,`minuto`)
VALUES (3,1,90);

INSERT INTO `segna`
(`ID_giocatore`,`ID_partita`,`minuto`)
VALUES (2,3,20);

INSERT INTO `segna`
(`ID_giocatore`,`ID_partita`,`minuto`)
VALUES (2,3,28);


INSERT INTO `direzione`
(`CF_arbitro`,`ID_partita`)
VALUES ("1234567890123456",1);

INSERT INTO `direzione`
(`CF_arbitro`,`ID_partita`)
VALUES ("1234567890123456",2);