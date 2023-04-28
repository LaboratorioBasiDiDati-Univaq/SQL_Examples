# Query di base

Seleziona tutte le colonne di tutte le righe di una tabella

```sql
SELECT * FROM partita
```

## Prodotto cartesiano con la clausola FROM

La FROM crea il prodotto cartesiano delle tabelle coinvolte

```sql
SELECT * FROM partita, luogo
```

## Ambiguità nei nomi di colonna

La clausola WHERE filtra i record generati dalla FROM (in questo caso, il prodotto cartesiano tra partita e luogo) in base a un'espressione logica sulle relative colonne. In questo caso però ci sarà un errore, perché nel prodotto cartesiano ci sono DUE colonne ID, quindi l'espressione WHERE ID=1 è ambigua

```sql
SELECT * FROM partita, luogo WHERE ID=1 (ERRORE)
```

Per eliminare le ambiguità, è possibile prefissare i nomi di colonne con quello delle rispettive tabelle

```sql
SELECT * FROM partita, luogo WHERE partita.ID = 1
```

Ovviamente il prefisso non è richiesto per colonne il cui nome non è ambiguo, ma può essere utile mettercelo comunque

```sql
SELECT * FROM partita, luogo WHERE ID_luogo = 1
```

```sql
SELECT * FROM partita, luogo WHERE partita.ID_luogo = 1
```

## Alias di tabella

Alternativamente, è possibile dare degli alias alle tabelle, e usare l'alias invece del nome della tabella per prefissare i nomi dei campi

```sql
SELECT * FROM partita AS p, luogo AS l WHERE p.ID = 1
```

*(SELECT \* FROM partita AS p, luogo AS l WHERE partita.ID = 1 non è corretto!)*

L'alias diventa necessario quando nella FROM si importa più volte la stessa tabella (che può essere utile per eseguire dei self join)

*(SELECT \* FROM partita, partita è ERRATO!)*

```sql
SELECT * FROM partita AS p1, partita AS p2
```

```sql
SELECT * FROM partita AS p1, partita AS p2 WHERE p1.ID=1
```

# Clausole WHERE complesse

Nelle clausole WHERE si possono scrivere espressioni complesse, che usano tutta la libreria di operatori di MySQL.

### "Le partite giocate negli ultimi trenta giorni"

Pensandoci, capiamo che per calcolare questo risultato dobbiamo filtrare le partite la cui data è maggiore di quella che è trenta giorni nel passato rispetto a oggi. Quest'ultima la possiamo calcolare scrivendo date_sub(now(), interval 30 day), quindi...

```sql
SELECT *
 FROM partita AS p
 WHERE p.data > date_sub(now(), interval 30 day)
```

### "I luoghi in cui si gioca a Roma"

```sql
SELECT *
 FROM luogo AS l
 WHERE l.citta = "Roma"
```

### "Le partite in cui si è segnato qualche punto"

#### Soluzione 1:

```sql
SELECT *
 FROM partita AS p
 WHERE p.punti_squadra_1 > 0 OR p.punti_squadra_2 > 0
```

#### Soluzione 2:

```sql
SELECT *
 FROM partita AS p
 WHERE p.punti_squadra_1 + p.punti_squadra_2 > 0
```

### "Le partite in cui si sono segnati almeno tre punti"

```sql
SELECT *
 FROM partita AS p
 WHERE p.punti_squadra_1 + p.punti_squadra_2 >= 3
```

### "Le partite in cui si sono segnati almeno da uno a quattro punti"

```sql
SELECT *
 FROM partita AS p
 WHERE (p.punti_squadra_1 + p.punti_squadra_2) BETWEEN 1 AND 4
```

### "I giocatori il cui nome comincia per P"

```sql
SELECT * FROM giocatore AS g WHERE g.nome LIKE "P%"
```

# La clausola SELECT

Nella clausola SELECT possiamo specificare quali delle colonne vogliamo effettivamente in output

```sql
SELECT p.ID FROM partita AS p, luogo AS l
```

```sql
SELECT p.ID, l.nome FROM partita AS p, luogo AS l
```

Possiamo anche usare l'asterisco per indicare "tutte le colonne di una certa tabella" (qui estraiamo l'ID della partita e tutte le colonne del luogo)

```sql
SELECT p.ID, l.* FROM partita AS p, luogo AS l
 WHERE l.ID=1
```

## Alias di colonna

Se in output vogliamo differenziare colonne con lo stesso nome (nel caso precedente ci sarebbero due colonne che si chiamano "ID") possiamo creare degli alias di colonna:

```sql
SELECT p.ID AS partita_ID, l.*
 FROM partita AS p, luogo AS l
 WHERE l.ID=1
```

```sql
SELECT p.ID AS partita_ID,l.ID AS luogo_ID
 FROM partita AS p, luogo AS l
 WHERE l.ID=1
```

```sql
SELECT p.ID AS partita_ID,l.ID AS luogo_ID, l.*
 FROM partita AS p, luogo AS l
 WHERE l.ID=1
```

```sql
SELECT p.ID AS partita_ID,l.ID AS luogo_ID, l.nome,l.citta
 FROM partita AS p, luogo AS l
 WHERE l.ID=1
```

## Colonne calcolate

È possibile anche estrarre colonne calcolate tramite espressioni generiche, che possono fare riferimento alle colonne:

```sql
SELECT p.ID AS partita_ID, (p.punti_squadra_1 + p.punti_squadra_2)
 FROM partita AS p
```

In tal caso, però, è sempre meglio dare un nome alla colonna calcolata con un alias

```sql
SELECT p.ID AS partita_ID,(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita AS p
```

Le colonne calcolate possono essere addirittura costanti:

```sql
SELECT p.ID AS partita_ID,"pippo" AS colonna_inutile,(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita AS p
```

Un'operazione di logica può essere usata come colonna calcolata, e in MySQL restituisce zero o uno a seconda del suo valore di verità

```sql
SELECT p.ID AS partita_ID,"pippo" AS colonna_inutile,
  p.punti_squadra_1 > p.punti_squadra_2 AS ha_vinto_1,
  p.punti_squadra_1 < p.punti_squadra_2 AS ha_vinto_2,
  (p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita AS p
```

Possiamo usare funzioni MySQL avanzate nelle colonne calcolate: ad esempio qui usiamo la funzione IF (due volte, nidificata) per generare un valore 0,1,2 a seconda del risultato della partita (pareggio, vittoria squadra1 o vittoria squadra 2)

```sql
SELECT p.ID AS partita_ID,"pippo" AS colonna_inutile,
  IF(p.punti_squadra_1 = p.punti_squadra_2,0, (IF(p.punti_squadra_1 > p.punti_squadra_2,1,2))) AS squadra_vincente,
  (p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita AS p
```

Ma ovviamente possiamo anche generare una stringa calcolata più significativa:

```sql
SELECT p.ID AS partita_ID,"pippo" AS colonna_inutile,
  IF(p.punti_squadra_1 = p.punti_squadra_2,"pareggio", 
   (IF(p.punti_squadra_1 > p.punti_squadra_2,"vittoria della squadra 1","vittoria della squadra 2"))) AS risultato,
  (p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita AS p
```

In questo esempio, invece, abbiamo una query colonna che riporta la lista di tutti i luoghi di gioco il cui nome è ottenuto combinando il relativo nome e la città

```sql
SELECT concat(l.nome, ' - ', l.citta) AS luogo FROM luogo l
```

## Selezione record distinti

Il modificatore DISTINCT fa in modo che la SELECT emetta solo record diversi tra loro:

```sql
SELECT DISTINCT l.citta FROM luogo l
```

Ovviamente il confronto viene eseguito su *tutto* il record, quindi la query che segue genererà due record con nome "L'Aquila", visto che comprendiamo anche l'ID nell'output:

```sql
SELECT DISTINCT l.ID,l.citta FROM luogo l
```