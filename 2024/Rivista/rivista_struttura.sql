-- creaimo il database, se non è già presente, e lo selezioniamo come default per tutte le istruzioni successive
CREATE DATABASE IF NOT EXISTS rivista;
USE rivista;

-- se stiamo effettuando delle prove, effettuiamo prima un drop di tutte le tabelle che stiamo per ricreare
-- alternativamente, potremmo cancellare l'intero database e ricrearlo
-- da notare che i drop vanno eseguiti in ordine opposto rispetto alle create per essere certi di non violare
-- alcun vincolo di integrità referenziale sui metadati

DROP TABLE IF EXISTS creazioneArticolo;
DROP TABLE IF EXISTS creazioneFigura;
DROP TABLE IF EXISTS impaginazioneFigure;
DROP TABLE IF EXISTS impaginazioneArticoli;
DROP TABLE IF EXISTS illustrazione;
DROP TABLE IF EXISTS articolo;
DROP TABLE IF EXISTS uscita;
DROP TABLE IF EXISTS figura;
DROP TABLE IF EXISTS freelance;
DROP TABLE IF EXISTS dipendente;
DROP TABLE IF EXISTS autore;

CREATE TABLE articolo (
    ID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    titolo VARCHAR(200) NOT NULL,
    testo TEXT NOT NULL
);

CREATE TABLE uscita (
    ID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    numero TINYINT UNSIGNED NOT NULL,
    tiratura INT UNSIGNED DEFAULT 0,
    data DATE NOT NULL,
    CONSTRAINT uscitaUnica UNIQUE (numero , `data`)
);

CREATE TABLE figura (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    altezza INTEGER UNSIGNED NOT NULL,
    larghezza INTEGER UNSIGNED NOT NULL,
    file VARCHAR(1024) NOT NULL,
    didascalia VARCHAR(1024),
    formato VARCHAR(50) NOT NULL,
    colori INTEGER NOT NULL
);

CREATE TABLE impaginazioneArticoli (
    ID_Articolo INT UNSIGNED NOT NULL,
    ID_Uscita INT UNSIGNED NOT NULL,
    origineX INTEGER,
    origineY INTEGER,
    altezza INTEGER,
    larghezza INTEGER,
    numeroPagina INTEGER UNSIGNED,
    PRIMARY KEY (ID_Articolo , ID_Uscita),
    CONSTRAINT impaginazione_articolo FOREIGN KEY (ID_Articolo)
        REFERENCES articolo (ID)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT impaginazione_articoli_uscita FOREIGN KEY (ID_Uscita)
        REFERENCES uscita (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE impaginazioneFigure (
    ID_Figura INT UNSIGNED NOT NULL,
    ID_Uscita INT UNSIGNED NOT NULL,
    origineX INTEGER,
    origineY INTEGER,
    altezza INTEGER,
    larghezza INTEGER,
    numeroPagina INTEGER UNSIGNED,
    PRIMARY KEY (ID_Figura , ID_Uscita),
    CONSTRAINT impaginazione_figura FOREIGN KEY (ID_Figura)
        REFERENCES figura (ID)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT impaginazione_figure_uscita FOREIGN KEY (ID_Uscita)
        REFERENCES uscita (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE illustrazione (
    ID_Articolo INT UNSIGNED NOT NULL,
    ID_Figura INT UNSIGNED NOT NULL,
    PRIMARY KEY (ID_Articolo , ID_Figura),
    CONSTRAINT illustrazione_articolo FOREIGN KEY (ID_Articolo)
        REFERENCES articolo (ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT illustrazione_figura FOREIGN KEY (ID_Figura)
        REFERENCES figura (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);
    
CREATE TABLE Autore (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    CF CHAR(16) UNIQUE,
    tipo ENUM('freelance', 'impiegato') DEFAULT 'impiegato' NOT NULL
);

CREATE TABLE Freelance (
    partitaIVA INTEGER UNSIGNED NOT NULL UNIQUE,
    ID_autore INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    CONSTRAINT freelance_autore FOREIGN KEY (ID_Autore)
        REFERENCES autore (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Dipendente (
    matricola INTEGER UNSIGNED NOT NULL UNIQUE,
    inizioRapporto DATE NOT NULL,
    fineRapporto DATE DEFAULT NULL,
    ID_autore INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    CONSTRAINT dipendente_autore FOREIGN KEY (ID_Autore)
        REFERENCES autore (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE creazioneArticolo (
    ID_Autore INTEGER UNSIGNED NOT NULL,
    ID_Articolo INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_Autore , ID_Articolo),
    CONSTRAINT creazioneArticolo_autore FOREIGN KEY (ID_Autore)
        REFERENCES autore (ID)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT creazioneArticolo_articolo FOREIGN KEY (ID_Articolo)
        REFERENCES articolo (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE creazioneFigura (
    ID_Autore INTEGER UNSIGNED NOT NULL,
    ID_Figura INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (ID_Autore , ID_Figura),
    CONSTRAINT creazioneFigura_autore FOREIGN KEY (ID_Autore)
        REFERENCES autore (ID)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT creazioneFigura_figura FOREIGN KEY (ID_Figura)
        REFERENCES figura (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);