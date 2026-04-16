-- creaimo il database, se non è già presente, e lo selezioniamo come default per tutte le istruzioni successive
CREATE DATABASE IF NOT EXISTS banca;
USE banca;

-- se stiamo effettuando delle prove, effettuiamo prima un drop di tutte le tabelle che stiamo per ricreare
-- alternativamente, potremmo cancellare l'intero database e ricrearlo
-- da notare che i drop vanno eseguiti in ordine opposto rispetto alle create per essere certi di non violare
-- alcun vincolo di integrità referenziale sui metadati

DROP TABLE IF EXISTS bonifico;
DROP TABLE IF EXISTS depositocontanti;
DROP TABLE IF EXISTS prelievocontanti;
DROP TABLE IF EXISTS giroconto;
DROP TABLE IF EXISTS bonifico;
DROP TABLE IF EXISTS assegno;
DROP TABLE IF EXISTS pagamentoelettronico;
DROP TABLE IF EXISTS movimento;
DROP TABLE IF EXISTS carnetassegni;
DROP TABLE IF EXISTS carta;
DROP TABLE IF EXISTS intestazione;
DROP TABLE IF EXISTS conto;
DROP TABLE IF EXISTS sportello;
DROP TABLE IF EXISTS filiale;
DROP TABLE IF EXISTS cliente;


CREATE TABLE cliente (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cognome VARCHAR(100) NOT NULL,
    CF CHAR(16) NOT NULL,
    CONSTRAINT cf_cliente_unico UNIQUE (CF)
);

CREATE TABLE filiale (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numero INT UNSIGNED NOT NULL,
    indirizzo VARCHAR(255) NOT NULL,
    CONSTRAINT numero_filiale_unico UNIQUE (numero)
);

CREATE TABLE sportello (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numero INT NOT NULL,
    indirizzo VARCHAR(255) NOT NULL,
    ID_filiale INT UNSIGNED NOT NULL,
    CONSTRAINT numero_sportello_unico UNIQUE (numero),
    CONSTRAINT sportello_filiale FOREIGN KEY (ID_filiale)
        REFERENCES filiale (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE conto (
    numero INT unsigned NOT NULL primary key,
    apertura DATE NOT NULL,
    IBAN CHAR(27) as (concat('prefissobanca',numero)) virtual,
    liquidita DECIMAL(15 , 2 ) NOT NULL DEFAULT 0.00 ,
    ID_filiale INT unsigned NOT NULL,
    CONSTRAINT conto_filiale FOREIGN KEY (ID_filiale)
        REFERENCES filiale(ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
        constraint liquidita_positiva CHECK (liquidita >= 0)
);

CREATE TABLE intestazione (
    numero_conto INT UNSIGNED NOT NULL,
    ID_cliente INT UNSIGNED NOT NULL,
    PRIMARY KEY (numero_conto , ID_cliente),
    CONSTRAINT intestazione_conto FOREIGN KEY (numero_conto)
        REFERENCES conto (numero)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT intestazione_cliente FOREIGN KEY (ID_cliente)
        REFERENCES cliente (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE carta (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numero CHAR(16) NOT NULL,
    PIN CHAR(5),
    circuito VARCHAR(50),
    massimale DECIMAL(10 , 2 ) NOT NULL,
    scadenza DATE NOT NULL,
    tipo ENUM('debito', 'credito') NOT NULL,
    numero_conto INT UNSIGNED NOT NULL,
    CONSTRAINT carta_unica UNIQUE (tipo , numero),
    CONSTRAINT carta_conto FOREIGN KEY (numero_conto)
        REFERENCES conto (numero)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT massimale_positivo CHECK (massimale > 0)
);

CREATE TABLE carnetassegni (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numero INT UNSIGNED NOT NULL,
    numeroPrimoassegno INT UNSIGNED NOT NULL,
    numeroUltimoassegno INT UNSIGNED NOT NULL,
    numero_conto INT UNSIGNED NOT NULL,
    CONSTRAINT carnet_unico UNIQUE (numero),
    CONSTRAINT carnet_conto FOREIGN KEY (numero_conto)
        REFERENCES conto (numero)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT range_assegni CHECK (numeroUltimoassegno >= numeroPrimoassegno)
);

CREATE TABLE movimento (
    ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    tipo ENUM('giroconto', 'pagamento_elettronico', 'assegno', 'bonifico', 'deposito_contanti', 'prelievo_contanti') NOT NULL,
    progressivo INT UNSIGNED NOT NULL,
    valore DECIMAL(12 , 2 ) NOT NULL,
    data DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descrizione VARCHAR(500),
    numero_conto INT UNSIGNED NOT NULL,
    CONSTRAINT movimento_unico UNIQUE (numero_conto , progressivo),
    CONSTRAINT movimento_conto FOREIGN KEY (numero_conto)
        REFERENCES conto (numero)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE giroconto (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    causale VARCHAR(255),
    numero_conto_destinazione INT UNSIGNED NOT NULL,
    CONSTRAINT giroconto_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT giroconto_conto_destunazione FOREIGN KEY (numero_conto_destinazione)
        REFERENCES conto (numero)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pagamentoelettronico (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    ID_carta INT UNSIGNED NOT NULL,
    codiceDestinatario VARCHAR(100) NOT NULL,
    CONSTRAINT pagamento_elettronico_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT pagamento_elettronico_carta FOREIGN KEY (ID_carta)
        REFERENCES carta (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE assegno (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    ID_carnetassegni INT UNSIGNED NOT NULL,
    numero INT UNSIGNED NOT NULL,
    intestatario VARCHAR(200) NOT NULL,
    CONSTRAINT assegno_unico UNIQUE (ID_carnetassegni , numero),
    CONSTRAINT assegno_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT assegno_carnet FOREIGN KEY (ID_carnetassegni)
        REFERENCES carnetassegni (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE bonifico (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    causale VARCHAR(255),
    IBAN_destinazione CHAR(27) NOT NULL,
    CONSTRAINT bonifico_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE depositocontanti (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    ID_sportello INT UNSIGNED NOT NULL,
    CONSTRAINT deposito_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT deposito_sportello FOREIGN KEY (ID_sportello)
        REFERENCES sportello (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE prelievocontanti (
    ID_movimento INT UNSIGNED PRIMARY KEY NOT NULL,
    ID_sportello INT UNSIGNED NOT NULL,
    CONSTRAINT prelievo_movimento FOREIGN KEY (ID_movimento)
        REFERENCES movimento (ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT prelievo_sportello FOREIGN KEY (ID_sportello)
        REFERENCES sportello (ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);