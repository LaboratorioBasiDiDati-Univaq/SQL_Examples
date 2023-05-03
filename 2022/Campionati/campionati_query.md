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

Ordinando le pertite in base ai punti totali e poi estraendo solo la prima sono sicuro di avere *una* partita in cui si sono segnati il massimo numero di punti. Tuttavia, se ci fossero dei "primi a pari merito" , cioè più partite con lo stesso, massimo numero di punti totali, in questo modo le taglierei fuori: l'unica estratta sarebbe dettata dal caso, o meglio dall'ordinamento dei record a pari punti deciso dal DBMS. Per questo, la soluzione di cui sopra, seppur semplice e lineare, non è quella corretta se ci possono essere più record al primo posto in classifica: più avanti vedremo vari modi di risolvere al meglio questo quesito.

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

Per raffinare questa query, potremmo voler mostrare anche il nome della squadra fuori casa, invece del suo ID. La procedura è la stessa: semplicemente, inseriremo una sotto-query anche nella clausola SELECT:

```sql
SELECT p.*,
(SELECT s.nome FROM squadra s WHERE s.ID=p.ID_squadra_2) AS nome_squadra_2
 FROM partita p
 WHERE p.ID_squadra_1 = (SELECT s.ID
 FROM squadra s
 WHERE s.nome="L'Aquila Calcio" AND s.citta="L'Aquila")
```

Notate come una sotto-query possa essere *relazionata* con la query esterna: nella sotto-query usata nella SELECT qui sopra, quando l'interprete deve valutare "p.ID_squadra_2", non trovando l'alias *p* nella query, va a cercarlo all'esterno. In questo modo il filtro WHERE della sotto-query imporrà che l'ID della squadra nella sotto-query sia uguale a quello della seconda squadra presente nel record della query esterna che la SELECT sta elaborando in quel momento. Notate inoltre che le due tabelle "squadra s" (con lo stesso alias) nelle due sotto-query non vanno in conflitto, in quanto le sotto-query sono distinte e non si "vedono" tra di loro.

## Operatore IN con query di tipo colonna

### "Le partite che si sono giocate a Roma"

Dobbiamo selezionare gli ID dei luoghi che sono situati a Roma:

```sql
SELECT l.ID FROM luogo l WHERE l.citta = "Roma"
```

E possiamo usarli come una lista, imponendo che il luogo della partita sia in essa contenuto:

```sql
SELECT * FROM partita p
 WHERE p.ID_luogo IN (SELECT l.ID FROM luogo l
 WHERE l.citta = "Roma")
```

Attenzione a selezionare *solo una colonna*, altrimenti la IN non funziona:

```sql
SELECT *
 FROM partita p
 WHERE p.ID_luogo IN (SELECT l.* FROM luogo l WHERE l.citta = "Roma")

-- Error Code: 1241. Operand should contain 1 column(s)
```

Potevamo usare anche un'uguaglianza?

```sql
SELECT *
 FROM partita p
 WHERE p.ID_luogo = (SELECT l.id FROM luogo l WHERE l.citta = "Roma")
```

ATTENZIONE! Questa query funziona *solo se c'è UN SOLO LUOGO a nella città indicata*, altrimenti...

```sql
SELECT *
 FROM partita p
 WHERE p.ID_luogo = (SELECT l.id FROM luogo l WHERE l.citta = "L'Aquila")

-- Error Code: 1242. Subquery RETURNS more than 1 row
```

## Modificatori ANY e ALL con operatori di confronto

In questi casi, cioè se vogliamo adattare un operatore di confronto a una lista, possiamo usare i modificatori ANY e ALL:

```sql
SELECT *
 FROM partita p
 WHERE p.ID_luogo = ANY (SELECT l.id FROM luogo l WHERE l.citta = "L'Aquila")
```

Qui diciamo che il luogo della partita deve essere "uguale a uno di quelli" che si trovano a L'Aquila. In pratica x = ANY (y,z) corrisponde a x=y OR x=z

### "Le partite in cui si sono segnati più punti in totale (versione corretta)"

Sappiamo calcolare i punti totali di una partita...

```sql
SELECT *, (punti_squadra_1+punti_squadra_2) AS punti
 FROM partita p
```

Quindi possiamo selezionare le partite il cui punteggio totale è maggiore o uguale a quello di tutte le altre partite:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 WHERE (p1.punti_squadra_1+p1.punti_squadra_2) >=
(SELECT (p2.punti_squadra_1+p2.punti_squadra_2) FROM partita p2)

-- Error Code: 1242. Subquery RETURNS more than 1 row
```

Eh no, l'operatore \>= non può lavorare su una lista, serve un adattatore, in questo caso ALL:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 WHERE (p1.punti_squadra_1+p1.punti_squadra_2) >= ALL
(SELECT (p2.punti_squadra_1+p2.punti_squadra_2) FROM partita p2)
```

In pratica x \>= ALL (y,z) corrisponde a x\>=y AND x\>=z

# I Join impliciti

### "Stampa il calendario delle partite"

Con calendario intendiamo data della partita e squadre coinvolte (ovviamente il tutto ordinato per data). Sappiamo stampare il calendario con gli ID delle squadre...

```sql
SELECT p.data, p.ID_squadra_1, p.ID_squadra_2
 FROM partita p
 ORDER BY p.data ASC
```

Ma come sostituire gli ID con i rispettivi nomi? Dobbiamo percorrere la relazione tra partita e squadra, cioè dobbiamo fare un JOIN tra queste due tabelle. Cominciamo con lo stampare solo la prima delle due squadre coinvolte...

```sql
SELECT p.data, s.nome AS squadra1
 FROM partita p, squadra s
 WHERE p.ID_squadra_1 = s.ID
 ORDER BY p.data ASC
```

La WHERE rappresenta qui la condizione di JOIN che filtra i record derivanti dal prodotto cartesiano generato dalla FROM.

A questo punto, per avere i nomi di due squadre distinte, dobbiamo fare due JOIN con la tabella squadra, ovviamente usando alias distinti:

```sql
SELECT p.data, s1.nome AS squadra1, s2.nome AS squadra2
 FROM partita p, squadra s1, squadra s2
 WHERE p.ID_squadra_1 = s1.ID AND p.ID_squadra_2 = s2.ID
 ORDER BY p.data ASC
```

Possiamo aggiungere anche il luogo dell'incontro, facendo un altro JOIN con la tabella luogo:

```sql
SELECT p.data, s1.nome AS squadra1, s2.nome AS squadra2, l.nome AS luogo
 FROM partita p, squadra s1, squadra s2, luogo l
 WHERE p.ID_squadra_1 = s1.ID AND p.ID_squadra_2 = s2.ID AND p.ID_luogo = l.ID
 ORDER BY p.data ASC
```

Possiamo anche concatenare i nomi delle due squadre e inserire la città relativa al luogo, per un output più "carino":

```sql
SELECT p.data, concat(s1.nome , " - ", s2.nome) AS squadre, concat(l.nome, " (", l.citta, ")") AS luogo
 FROM partita p, squadra s1, squadra s2, luogo l
 WHERE p.ID_squadra_1 = s1.ID AND p.ID_squadra_2 = s2.ID AND p.ID_luogo = l.ID
 ORDER BY p.data ASC
```

### "La formazione de L'Aquila Calcio del 2020"

La tabella formazione può essere filtrata per l'anno 2020 e ordinata per numero di maglia...

```sql
SELECT *
 FROM formazione f
 WHERE f.anno=2020
 ORDER BY f.numero ASC
```

Ma dobbiamo anche filtrarla in base a una certa squadra. Sapendo che L'Aquila Calcio ha ID=1 potremmo semplicemente scrivere

```sql
SELECT *
 FROM formazione f
 WHERE f.anno=2020 AND f.ID_squadra=1
 ORDER BY f.numero ASC
```

Ora dobbiamo aggiungere i nomi dei giocatori, facendo un JOIN con la rispettiva tabella

```sql
SELECT f.numero, g.nome, g.cognome
 FROM formazione f, giocatore g
 WHERE f.anno=2020 AND f.ID_squadra=1 AND g.ID = f.ID_giocatore
 ORDER BY f.numero ASC
```

Però così abbiamo inserito l'ID della squadra nella query, non il suo nome. Sappiamo come estrarre l'ID dell'Aquila Calcio:

```sql
SELECT s.ID
 FROM squadra s
 WHERE s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila"
```

Attenzione: siamo sicuri che questa query ritorna un *singleton* (un solo valore) perché nella definizione della tabella squadra c'è una UNIQUE sulla coppia (nome,città). Possiamo quindi usare questa come sotto-query con un confronto diretto:

```sql
SELECT f.numero, g.nome, g.cognome
 FROM formazione f, giocatore g
 WHERE f.anno=2020 AND f.ID_squadra = 
  (SELECT s.ID FROM squadra s WHERE s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila") AND g.ID = f.ID_giocatore
 ORDER BY f.numero ASC
```

In realtà, la stessa cosa si può ottenere senza la sotto query, facendo un JOIN con squadra e filtrando in base alla squadra selezionata:

```sql
SELECT f.numero, g.nome, g.cognome
 FROM formazione f, giocatore g, squadra s
 WHERE f.anno=2020 AND s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila" AND g.ID = f.ID_giocatore AND f.ID_squadra = s.ID
 ORDER BY f.numero ASC
```

# I Join espliciti (operatore JOIN)

## Join interni (INNER JOIN)

Sappiamo che di default più tabelle nella clausola FROM vengono combinate con un prodotto cartesiano:

```sql
SELECT p.ID, l.nome
 FROM partita p, luogo l
 WHERE p.ID_luogo = l.ID
```

ma questo può essere reso esplicito usando l'operatore CROSS JOIN, se vogliamo:

```sql
SELECT p.ID, l.nome
 FROM partita p CROSS JOIN luogo l
 WHERE p.ID_luogo = l.ID
```

tutti gli altri JOIN, che usano una condizione, possono essere invece espressi nella clausola FROM usando l'operatore (INNER) JOIN...ON e spostando la condizione di JOIN in questo costrutto:

```sql
SELECT p.ID, l.nome
 FROM partita p INNER JOIN luogo l ON (p.ID_luogo = l.ID)
```

esiste anche il NATURAL JOIN, che mette in corrispondenza le colonne aventi lo stesso nome, cioè mette insieme i record aventi valori uguali nelle colonne omonime delle due tabelle:

```sql
SELECT p.ID, l.nome
 FROM partita p NATURAL JOIN luogo l
```

tuttavia, il "normale" INNER JOIN, con la regola di JOIN esplicitata, è comunque più chiaro da leggere e interpretare in ogni caso.

### "La formazione de L'Aquila Calcio del 2020" -- versione con JOIN espliciti

```sql
SELECT f.numero, g.nome, g.cognome
 FROM formazione f JOIN giocatore g ON (g.ID = f.ID_giocatore)
  JOIN squadra s ON (f.ID_squadra = s.ID)
 WHERE f.anno=2020 AND s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila"
 ORDER BY f.numero ASC
```
