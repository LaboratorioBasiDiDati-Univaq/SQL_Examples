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

# Ordinamento dei risultati (ORDER BY)

Possiamo ordinare i risultati di una query:

```sql
SELECT *
 FROM giocatore
 ORDER BY nome
```

...specificando la direzione di ordinamento (ascendente o discendente)

```sql
SELECT *
 FROM giocatore
 ORDER BY nome DESC
```

...e anche in base a più criteri

```sql
SELECT *
 FROM giocatore
 ORDER BY cognome, luogo_nascita ASC
```

È possibile utilizzare alias di colonne, anche calcolate, come criteri di ordinamento:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 ORDER BY punti DESC
```

ma anche semplici espressioni:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 ORDER BY (p1.punti_squadra_1+p1.punti_squadra_2) DESC
```

Infine, si possono usare dei numeri, che corrispondono a indici delle colonne di output

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 ORDER BY 9 DESC
```

Qui i punti sono nella colonna nove in quanto la \* viene espansa in otto colonne.

# Limitazione dell'output (LIMIT)

### "La prima partita del 2020"

Basta ordinare le partite per data, e farci restituire solo il primo record:

```sql
SELECT *
 FROM partita p
 WHERE extract(year FROM p.data)=2020
 ORDER BY data ASC
 LIMIT 1
```

Ma se ci fossero più partite giocate esattamente nello stesso giorno e alla stessa ora? Quale sarebbe la "prima"? In questo caso la query è ambigua, perchè pare suggerirci che la *prima* partita sia solo *una*, quindi andrebbe capito se questa formulazione è valida nel caso particolare appena esposto. Vedremo questo stesso problema anche in uno
degli esempi successivi, e più avanti capiremo come risolverlo.

## Paginazione dei risultati di una query

La clausola LIMIT si usa spesso per paginare i record: la prima partita la possiamo estrarre anche scrivendo, più genericamente:

```sql
SELECT *
 FROM partita p
 WHERE extract(year FROM p.data)=2020
 ORDER BY data ASC
 LIMIT 0,1
```

...poi la seconda

```sql
SELECT *
 FROM partita p
 WHERE extract(year FROM p.data)=2020
 ORDER BY data ASC
 LIMIT 1,1
```

...e così via.

### "Le partite in cui si sono segnati più punti in totale (versione scorretta)"

Usando opportunamente ORDER BY e LIMIT è possibile scrivere query che generano "classifiche" come quella richiesta dal quesito in oggetto. Infatti, una soluzione al quesito di cui sopra potrebbe essere la query che segue:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 ORDER BY punti DESC
 LIMIT 1
```

Ordinando le partite in base ai punti totali e poi estraendo solo la prima sono sicuro di avere *una* partita in cui si sono segnati il massimo numero di punti. Tuttavia, se ci fossero dei "primi a pari merito" (d'altra parte la specifica dice "*le partite*", quindi contempla esplicitamente questa eventualità!), cioè più partite con lo stesso massimo numero di punti totali, in questo modo le taglierei fuori: l'unica estratta sarebbe dettata dal caso, o meglio dall'ordinamento dei record a pari punti deciso dal DBMS. Per questo, la soluzione di cui sopra, seppur semplice e lineare, non è quella corretta se ci possono essere più record al primo posto in classifica: più avanti vedremo vari modi di risolvere al meglio questo quesito.

# Sotto-query (semplici)

È possibile nidificare una query in un'altra usando varie modalità. Vediamo le più semplici, che coinvolgono la clausola WHERE e alcuni operatori interessanti.

## Query scalari (singleton)

Le query scalari possono essere utilizzate come qualsiasi espressione che ritorni un valore, quindi in particolare con ogni operatore SQL adatto.

### "Le partite in cui il L'Aquila Calcio gioca in casa"

Supponiamo che chi gioca in casa sia sempre la "squadra 1" della partita. Sappiamo filtrare le partite in base a questo criterio:

```sql
SELECT p.*
 FROM partita p
 WHERE p.ID_squadra_1 = 1
```

ma la query presuppone che noi sappiamo a priori che l'ID del L'Aquila Calcio è 1. D'altra parte, sappiamo anche come estrarre l'ID di una squadra dato il suo nome:

```sql
SELECT s.ID
 FROM squadra s
 WHERE s.nome = "L'Aquila Calcio"
```

Attenzione: siamo sicuri che questa query ritorni un singleton (un solo valore)? In realtà non è detto (anche se in questo esempio pare scontato), perché nella definizione della tabella *squadra* c'è una UNIQUE sulla coppia (*nome* ,*citta* ) e non sul solo *nome*. Quindi l'unica versione "sicura" della query di cui sopra è quella in cui il filtro agisce anche sulla città:

```sql
SELECT s.ID
 FROM squadra s
 WHERE s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila"
```

A questo punto, possiamo combinare le due query usando la seconda come espressione all'interno della clausola WHERE della prima:

```sql
SELECT p.*
 FROM partita p
 WHERE p.ID_squadra_1 = (SELECT s.ID
 FROM squadra s
 WHERE s.nome="L'Aquila Calcio" AND s.citta="L'Aquila")
```
