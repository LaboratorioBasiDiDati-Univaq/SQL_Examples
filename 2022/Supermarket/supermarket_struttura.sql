-- creaimo il database, se non è già presente, e lo selezioniamo come default per tutte le istruzioni successive
CREATE DATABASE IF NOT EXISTS supermarket;
USE supermarket;

-- se stiamo effettuando delle prove, effettuiamo prima un drop di tutte le tabelle che stiamo per ricreare
-- alternativamente, potremmo cancellare l'intero database e ricrearlo
-- da notare che i drop vanno eseguiti in ordine opposto rispetto alle create per essere certi di non violare
-- alcun vingolo di integrità referenziale sui metadati
DROP TABLE IF EXISTS contiene;
DROP TABLE IF EXISTS scontrino;
DROP TABLE IF EXISTS telefono;
DROP TABLE IF EXISTS compone;
DROP TABLE IF EXISTS prodotto;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS fornitore;
DROP TABLE IF EXISTS reparto;

CREATE TABLE reparto (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE fornitore (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    partitaIVA INTEGER UNSIGNED NOT NULL UNIQUE,
    ragioneSociale VARCHAR(200) NOT NULL,
    indirizzo VARCHAR(200),
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(100) NOT NULL,
    fax VARCHAR(100)
);

CREATE TABLE cliente (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    numeroTessera INTEGER UNSIGNED NOT NULL UNIQUE,
    nome VARCHAR(200) NOT NULL,
    cognome VARCHAR(200) NOT NULL,
    email VARCHAR(100)
);

CREATE TABLE prodotto (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(200) NOT NULL,
    codice CHAR(6) NOT NULL UNIQUE,
    tipo ENUM('s', 'c') NOT NULL DEFAULT 's',
    prezzo FLOAT,
    ID_reparto INTEGER UNSIGNED,
    ID_fornitore INTEGER UNSIGNED NOT NULL,
    CONSTRAINT prodotto_reparto FOREIGN KEY (ID_reparto)
        REFERENCES reparto (ID)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT prodotto_fornitore FOREIGN KEY (ID_fornitore)
        REFERENCES fornitore (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT controllo_formato_codice CHECK (codice LIKE 'C%')
);

CREATE TABLE compone (
    quantita FLOAT NOT NULL DEFAULT 1,
    ID_prodotto_base INTEGER UNSIGNED NOT NULL,
    ID_prodotto_derivato INTEGER UNSIGNED NOT NULL,
    CONSTRAINT compone_base FOREIGN KEY (ID_prodotto_base)
        REFERENCES prodotto (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT compone_derivato FOREIGN KEY (ID_prodotto_derivato)
        REFERENCES prodotto (ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (ID_prodotto_base , ID_prodotto_derivato)
);

CREATE TABLE telefono (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    etichetta VARCHAR(50),
    numero VARCHAR(100) NOT NULL,
    ID_fornitore INTEGER UNSIGNED NOT NULL,
    CONSTRAINT telefono_fornitore FOREIGN KEY (ID_fornitore)
        REFERENCES fornitore (ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE scontrino (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    numero INTEGER UNSIGNED NOT NULL,
    `data` DATETIME NOT NULL,
    ID_cliente INTEGER UNSIGNED,
    CONSTRAINT scontrino_distinto UNIQUE (data , numero),
    CONSTRAINT scontrino_cliente FOREIGN KEY (ID_cliente)
        REFERENCES cliente (ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE contiene (
    ID INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    ID_prodotto INTEGER UNSIGNED NOT NULL,
    ID_scontrino INTEGER UNSIGNED NOT NULL,
    CONSTRAINT contiene_prodotto FOREIGN KEY (ID_prodotto)
        REFERENCES prodotto (ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT contiene_scontrino FOREIGN KEY (ID_scontrino)
        REFERENCES scontrino (ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);