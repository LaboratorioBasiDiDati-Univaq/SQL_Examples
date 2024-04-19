-- creaimo il database, se non è già presente, e lo selezioniamo come default per tutte le istruzioni successive
CREATE DATABASE IF NOT EXISTS azienda;
USE azienda;

-- se stiamo effettuando delle prove, effettuiamo prima un drop di tutte le tabelle che stiamo per ricreare
-- alternativamente, potremmo cancellare l'intero database e ricrearlo
-- da notare che i drop vanno eseguiti in ordine opposto rispetto alle create per essere certi di non violare
-- alcun vingolo di integrità referenziale sui metadati
DROP TABLE IF EXISTS haLavorato;
DROP TABLE IF EXISTS composto;
DROP TABLE IF EXISTS fornisce;
DROP TABLE IF EXISTS ubicato;
DROP TABLE IF EXISTS telefono;
DROP TABLE IF EXISTS impiegato;
DROP TABLE IF EXISTS fornitore;
DROP TABLE IF EXISTS sede;
DROP TABLE IF EXISTS prodotto;
DROP TABLE IF EXISTS reparto;
DROP TABLE IF EXISTS componente;


CREATE TABLE sede (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    civico VARCHAR(10) NOT NULL,
    via VARCHAR(100) NOT NULL,
    citta VARCHAR(100) NOT NULL,
    CONSTRAINT sede_unica UNIQUE (civico , via , citta)
);

CREATE TABLE reparto (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    codice CHAR(4) UNIQUE NOT NULL
);

CREATE TABLE ubicato (
    ID_sede INTEGER UNSIGNED NOT NULL,
    ID_reparto INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_sede , ID_reparto),
    CONSTRAINT ubicato_reparto FOREIGN KEY (ID_reparto)
        REFERENCES reparto (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ubicato_sede FOREIGN KEY (ID_sede)
        REFERENCES sede (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE impiegato (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    matricola INTEGER UNSIGNED NOT NULL UNIQUE,
    CF CHAR(16) NOT NULL UNIQUE,
    ruolo VARCHAR(10),
    ID_sede INTEGER UNSIGNED NOT NULL,
    ID_reparto INTEGER UNSIGNED,
    dirige_reparto SMALLINT,
    data_inizio_incarico_reparto DATE,
    data_inizio_impiego DATE NOT NULL,
    data_fine_impiego DATE,
    CONSTRAINT ruolo_corretto CHECK (ruolo IN ('impiegato' , 'dirigente')),
    CONSTRAINT dirige_booleano1 CHECK (dirige_reparto BETWEEN 0 AND 1),
    CONSTRAINT impiegato_sede FOREIGN KEY (ID_sede)
        REFERENCES sede (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT impiegato_reparto FOREIGN KEY (ID_reparto)
        REFERENCES reparto (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE haLavorato (
    dataInizio DATE NOT NULL,
    dataFine DATE NOT NULL,
    dirige SMALLINT NOT NULL DEFAULT 0,
    ID_impiegato INTEGER UNSIGNED NOT NULL,
    ID_reparto INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_impiegato , ID_reparto , dataInizio , dataFine),
    CONSTRAINT dirige_booleano2 CHECK (dirige BETWEEN 0 AND 1),
    CONSTRAINT halavorato_reparto FOREIGN KEY (ID_reparto)
        REFERENCES reparto (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT halavorato_impiegato FOREIGN KEY (ID_impiegato)
        REFERENCES impiegato (ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE prodotto (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    codice CHAR(12) NOT NULL UNIQUE,
    ID_reparto INTEGER UNSIGNED NOT NULL,
    CONSTRAINT prodotto_reparto FOREIGN KEY (ID_reparto)
        REFERENCES reparto (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE componente (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    descrizione VARCHAR(1024),
    codice CHAR(12) NOT NULL UNIQUE
);

CREATE TABLE composto (
    ID_prodotto INTEGER UNSIGNED NOT NULL,
    ID_componente INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_prodotto , ID_componente),
    CONSTRAINT composto_prodotto FOREIGN KEY (ID_prodotto)
        REFERENCES prodotto (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT composto_componente FOREIGN KEY (ID_componente)
        REFERENCES componente (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE fornitore (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ragioneSociale VARCHAR(200) NOT NULL,
    partitaIVA INTEGER UNSIGNED NOT NULL UNIQUE,
    civico VARCHAR(10),
    via VARCHAR(100),
    citta VARCHAR(100),
    email VARCHAR(1024)
);

CREATE TABLE fornisce (
    ID_componente INTEGER UNSIGNED NOT NULL,
    ID_fornitore INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_componente , ID_fornitore),
    CONSTRAINT fornisce_componente FOREIGN KEY (ID_componente)
        REFERENCES componente (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fornisce_fornitore FOREIGN KEY (ID_fornitore)
        REFERENCES fornitore (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE telefono (
    ID INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(30) NOT NULL UNIQUE,
    etichetta VARCHAR(20) DEFAULT 'lavoro',
    ID_fornitore INTEGER UNSIGNED NOT NULL,
    CONSTRAINT telefono_fornitore FOREIGN KEY (ID_fornitore)
        REFERENCES fornitore (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);