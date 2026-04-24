-- selezioniamo il database di default per tutte le istruzioni successive
USE banca;

-- svuotiamo le tabelle
DELETE FROM bonifico;
DELETE FROM depositocontanti;
DELETE FROM prelievocontanti;
DELETE FROM giroconto;
DELETE FROM assegno;
DELETE FROM pagamentoelettronico;
DELETE FROM movimento;
DELETE FROM carnetassegni;
DELETE FROM carta;
DELETE FROM intestazione;
DELETE FROM conto;
DELETE FROM sportello;
DELETE FROM filiale;
DELETE FROM cliente;

INSERT INTO cliente (ID, nome, cognome, CF) VALUES
 (1, 'Marco', 'Rossi', 'RSSMRC80A01H501Z'),
 (2, 'Laura', 'Bianchi', 'BNCLRA85M41F205X'),
 (3, 'Giuseppe', 'Verdi', 'VRDGPP72T10L219K'),
 (4, 'Anna', 'Ferrari', 'FRRNNA90D54G702W'),
 (5, 'Luca', 'Esposito', 'SPSLCU95P15A662Q'),
 (6, 'Chiara', 'Ricci', 'RCCCHR88C41D612M');

INSERT INTO filiale (ID, numero, indirizzo) VALUES
 (1, 1, 'Via Roma 1, L''Aquila'),
 (2, 2, 'Corso Umberto 45, Roma'),
 (3, 3, 'Via Nazionale 12, Milano');

INSERT INTO sportello (ID, numero, indirizzo, ID_filiale) VALUES
 (1, 101, 'Via Roma 1, L''Aquila', 1),
 (2, 102, 'Via Roma 12, L''Aquila', 1),
 (3, 201, 'Corso Umberto 45, Roma', 2),
 (4, 301, 'Via Nazionale 12, Milano', 3),
 (5, 302, 'Via Roma 12, Milano', 3);

INSERT INTO conto (numero, apertura, liquidita, ID_filiale) VALUES
 (1, '2018-03-15', 15420.50, 1),
 (2, '2019-07-22', 3200.00, 1),
 (3, '2020-01-10', 87500.00, 2),
 (4, '2021-05-30', 500.75, 3),
 (5, '2022-11-01', 22000.00, 3);

INSERT INTO intestazione (numero_conto, ID_cliente) VALUES
 (1, 1),
 (2, 2),
 (3, 3), -- conto 3 cointestato
 (3, 4), -- conto 3 cointestato
 (4, 5), 
 (5, 6); 

INSERT INTO carta (ID, numero, PIN, circuito, massimale, scadenza, tipo, numero_conto) VALUES
 (1, '4532015112830366', '1234', 'Bancomat', 1500.00, '2027-12-31', 'debito', 1),
 (2, '5425233430109903', '5678', 'Mastercard', 3000.00, '2026-06-30', 'credito', 1),
 (3, '4916338506082832', '9012', 'Visa', 500.00, '2028-03-31', 'credito', 2),
 (4, '4485275742308327', '3456', 'Bancomat', 2000.00, '2026-09-30', 'debito', 3),
 (5, '5425233430101234', '7890', 'Mastercard', 5000.00, '2027-05-31', 'credito', 3),
 (6, '4532015112831111', '2468', 'Bancomat', 800.00, '2028-12-31', 'debito', 5);

INSERT INTO carnetassegni (ID, numero, numeroPrimoassegno, numeroUltimoassegno, numero_conto) VALUES
 (1, 1001, 1, 10, 1),
 (2, 1002, 11, 20, 1),
 (3, 2001, 1, 10, 3);

INSERT INTO movimento (ID, tipo, progressivo, valore, data, descrizione, numero_conto) VALUES
 ( 1, 'deposito_contanti', 1, 500.00, '2024-01-10 09:15:00', 'Versamento contanti', 1),
 ( 2, 'bonifico', 2, 1200.00, '2024-01-15 11:30:00', 'Pagamento affitto gennaio', 1),
 ( 3, 'giroconto', 3, 300.00, '2024-02-01 10:00:00', 'Trasferimento a conto 2', 1),
 ( 4, 'pagamento_elettronico', 4, 89.99, '2024-02-14 18:45:00', 'Acquisto online', 1),
 ( 5, 'assegno', 5, 250.00, '2024-03-05 08:00:00', 'Pagamento artigiano', 1),
 ( 6, 'prelievo_contanti', 6, 200.00, '2024-03-20 14:00:00', 'Prelievo sportello', 1),
 ( 7, 'deposito_contanti', 1, 300.00, '2024-02-01 10:05:00', 'Ricezione giroconto', 2),
 ( 8, 'pagamento_elettronico', 2, 45.00, '2024-02-20 20:10:00', 'Abbonamento streaming', 2),
 ( 9, 'bonifico', 3, 150.00, '2024-04-01 09:00:00', 'Rimborso spese', 2),
 (10, 'bonifico', 1, 50000.00, '2024-01-02 09:00:00', 'Apertura conto - accredito', 3),
 (11, 'pagamento_elettronico', 2, 1200.00, '2024-02-10 12:00:00', 'Pagamento fornitore', 3),
 (12, 'assegno', 3, 800.00, '2024-03-15 10:30:00', 'Pagamento consulenza', 3),
 (13, 'prelievo_contanti', 1, 50.00, '2024-03-01 16:00:00', 'Prelievo contanti', 4),
 (14, 'bonifico', 1, 2000.00, '2024-01-20 08:30:00', 'Stipendio gennaio', 5),
 (15, 'giroconto', 2, 500.00, '2024-02-05 11:00:00', 'giroconto interno', 5);

INSERT INTO giroconto (ID_movimento, causale, numero_conto_destinazione) VALUES
 ( 3, 'Trasferimento mensile a conto secondario', 2),
 (15, 'Rimborso prestito familiare', 1);

INSERT INTO Pagamentoelettronico (ID_movimento, ID_carta, codiceDestinatario) VALUES
 ( 4, 1, 'AMZN_IT_0042'),
 ( 8, 3, 'NETFLIX_EU_01'),
 (11, 4, 'FORN_2024_0099');

INSERT INTO assegno (ID_movimento, ID_carnetassegni, numero, intestatario) VALUES
 ( 5, 1, 1, 'Idraulica Centrale S.r.l.'),
 (12, 3, 1, 'Studio Legale Moretti');

INSERT INTO bonifico (ID_movimento, causale, IBAN_destinazione) VALUES
 ( 2, 'Affitto gennaio 2024', 'IT84S0300203280537861418671'),
 ( 9, 'Rimborso cena sociale', 'IT60X0542811101000000123456'),
 (10, 'Conferimento capitale iniziale', 'IT94P0542811101000000654321'),
 (14, 'Stipendio gennaio 2024', 'IT47B0542811103000000901234');

INSERT INTO depositocontanti (ID_movimento, ID_sportello) VALUES
 (1, 1),
 (7, 2);

INSERT INTO prelievocontanti (ID_movimento, ID_sportello) VALUES
 ( 6, 1),
 (13, 4);
