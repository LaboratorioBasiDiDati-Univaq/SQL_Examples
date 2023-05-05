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

### "I marcatori della partita 1"

Sappiamo che i marcatori, cioè i giocatori che hanno segnato, possono essere estratti dalla tabella segna, filtrandola in base alla partita:

```sql
SELECT * FROM segna e WHERE e.ID_partita = 1
```

se vogliamo anche il nome dei giocatori, dobbiamo fare un JOIN con la tabella giocatore:

```sql
SELECT g.nome, g.cognome, e.minuto
 FROM segna e JOIN giocatore g ON (e.ID_giocatore=g.ID)
 WHERE e.ID_partita = 1
```

e se vogliamo capire per che squadra giocava il giocatore che ha segnato, dobbiamo collegare il giocatore alla squadra tramite la formazione:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, e.minuto
 FROM segna e JOIN giocatore g ON (e.ID_giocatore=g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
 WHERE e.ID_partita = 1
 ORDER BY e.minuto ASC
```

Questa query però è SBAGLIATA. Infatti, in questo modo colleghiamo i giocatori a tutte le formazioni di cui hanno fatto parte, mentre ci serve solo la formazione, e quindi la squadra, in cui giocavano in quella data partita.

Riflettendo, ci accorgiamo che la formazione ha come ulteriore attributo un anno. Potremmo allora confrontare l'anno della formazione con quello estratto dalla data della partita. Facciamo quindi un ulteriore JOIN tra segna e partita e procediamo come segue, usando l'operatore extract di MySQL:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, e.minuto
 FROM segna e JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
 WHERE e.ID_partita = 1 AND extract(year FROM p.data) = f.anno
 ORDER BY e.minuto ASC
```

Ottimo! Ma se, come per i campionati di calcio, le partite dello stesso campionato possono giocarsi in due anni diversi? La formazione a quale dei due anni fa riferimento? In generale, in questi casi si specifica l'anno iniziale della coppia. Ma allora la query precedente non funziona, ad esempio, se la formazione è marcata 2019, essendo riferita al campionato 2019/2020, ma la partita si svolge nel 2020!

Come possiamo risolvere? Potremmo "ragionare" sulla data della partita, cercando di estrarre l'anno giusto sulla base del mese, scrivendo una query come quella che segue, che sfrutta il costrutto IF di MySQL:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, e.minuto
 FROM segna e JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
 WHERE e.ID_partita = 1 AND IF (EXTRACT(MONTH FROM p.data) >= 9, extract(year FROM p.data), extract(year FROM p.data)-1) = f.anno
 ORDER BY e.minuto ASC
```

Ma saremmo troppo "legati" ai mesi in cui si possono giocare le partite di un certo campionato. La soluzione migliore, guardando il nostro database, è usare l'anno che è scritto nel campionato a cui appartiene la partita, in modo da poter semplicemente richiedere che l'anno della formazione sia lo stesso del campionato:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, e.minuto
 FROM segna e JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE e.ID_partita = 1 AND (c.anno=f.anno)
 ORDER BY e.minuto ASC
```

## Join esterni (OUTER JOIN)

### "Lista dei giocatori con le squadre in cui hanno giocato nel 2020"

```sql
SELECT g.nome, g.cognome, s.nome AS squadra
 FROM giocatore g 
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra= s.ID)
 WHERE f.anno=2020
```

Ma se un giocatore non ha giocato nel 2020? Il JOIN lo esclude! Se volessimo vedere proprio tutti i giocatori, con le squadre in cui eventualmente hanno giocato nel 2020, potremmo usare un JOIN esterno:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra
 FROM giocatore g
  LEFT JOIN (formazione f JOIN squadra s ON (f.ID_squadra= s.ID)) 
  ON (f.ID_giocatore = g.ID)
 WHERE f.anno=2020
```

In questo caso tutti i record dei giocatori vengono inseriti nel risultato, completati se possibile con quelli del sotto-JOIN (tra parentesi) tra formazione e squadra. Vediamo quindi anche come si può usare un JOIN come una vera e propria tabella, raggruppandolo con delle parentesi e inserendolo come operando in un altro JOIN.

Però anche questa soluzione non funziona. Perché? Perché i giocatori che non hanno giocato non avranno una formazione associata, quindi per loro f.anno sarà nullo, e verranno esclusi dal filtro WHERE. La soluzione è considerare questa evenienza:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra
 FROM giocatore g
  LEFT JOIN (formazione f JOIN squadra s ON (f.ID_squadra= s.ID))
  ON (f.ID_giocatore = g.ID)
 WHERE f.anno IS NULL OR f.anno=2020
```

oppure spostare il filtro sull'anno dalla WHERE alla condizione del sotto-JOIN tra squadra e formazione, in modo che questo avvenga solo per le formazioni del 2020, e quindi il JOIN più esterno colleghi direttamente i giocatori alle squadre in cui hanno eventualmente giocato nel 2020:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, f.anno
 FROM giocatore g
  LEFT JOIN (formazione f JOIN squadra s ON (f.ID_squadra = s.ID AND f.anno=2020))
  ON (f.ID_giocatore = g.ID)
```

# Operatori aggregati

### "Numero partite giocate nel campionato del 2020"

La soluzione è contare i record derivanti dalla query che segue:

```sql
SELECT p.*
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Ma se volessimo farli contare dal DBMS? La soluzione è chiedere che i record siano aggregati e su di essi venga applicato un operatore di aggregazione, come COUNT:

```sql
SELECT count(*)
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Notare che è possibile contare anche i valori di una certa espressione, ma il risultato è in generale identico a COUNT(\*), tranne quando ci sono valori null: in questo caso COUNT(espressione) conta solo i valori NON NULLI.

```sql
SELECT count(p.ID) AS numero_partite
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

```sql
SELECT count(c.ID) AS numero_partite
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Le due query di cui sopra forniscono lo stesso risultato, perché tutte le istanze di c.ID, seppure uguali (tutte le partite sono nello stesso campionato), vengono contate. Possiamo però chiedere a SQL di contare solo il numero di valori DISTINTI e NON NULLI:

```sql
SELECT count(DISTINCT c.ID)
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Quando si usa un operatore aggregato, si possono inserire nella clausola SELECT delle espressioni non aggregate solo se queste sono funzionalmente dipendenti dall'aggregazione. Ad esempio, l'ID del campionato (c.ID) è unico in tutti i record aggregati, come abbiamo visto, quindi è possibile richiederlo in output:

```sql
SELECT c.ID, count(*) AS numero_partite
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Ma l'ID della partita non è unico, quindi l'espressione che segue è scorretta:

```sql
SELECT p.ID, count(*) AS numero_partite
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

In base alla configurazione, il DBMS potrebbe anche far "passare" la query precedente, ma in tal caso la colonna p.ID avrebbe un risultato non significativo (di solito il p.ID del primo record dell'aggregazione). In altri casi, il DBMS potrebbe bloccare anche operazioni legittime come quella in cui si estrae il c.ID vista sopra.

Possiamo però inserire liberamente altre colonne calcolate con operatori aggregati nella stessa query. Ad esempio, numero di partite e numero totale di punti segnati (operatore SUM):

```sql
SELECT count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

oppure anche le date di inizio e fine campionato (prima e ultima partita, operatori MIN e MAX):

```sql
SELECT count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali,
  min(p.data) AS prima_partita,
  max(p.data) AS ultima_partita,
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

o ancora la media dei punti per partita (operatore AVG):

```sql
SELECT count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali,
  min(p.data) AS prima_partita,
  max(p.data) AS ultima_partita,
  avg(p.punti_squadra_1 + p.punti_squadra_2) AS media_punti_partita
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

# Raggruppamento di record (GROUP BY)

### "Numero partite giocate e punti totali segnati in ciascun luogo di gioco nel 2020"

Ovviamente la query di cui sopra non risolve questa richiesta, anche se mettiamo le partite in relazione con i relativi luoghi di svolgimento

```sql
SELECT l.nome,count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
```

in quanto i conteggi ottenuti sono sempre relativi a TUTTE le partite, e non partizionati rispetto ai luoghi. In questo caso, dobbiamo eseguire un raggruppamento dei record (partite) usando il luogo come criterio e calcolando i valori aggregati su ciascuna partizione. È esattamente ciò che fa la clausola GROUP BY:

```sql
SELECT l.nome,count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
 GROUP BY l.nome
```

In realtà la query di cui sopra non è del tutto corretta, in quanto i luoghi sono distinti (UNIQUE) dalla coppia (nome, città), quindi per poterli effettivamente elencare tutti dobbiamo raggruppare per entrambe queste colonne:

```sql
SELECT l.nome,l.citta,count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
 GROUP BY l.nome,l.citta
```

sarebbe più comodo raggruppare direttamente per l'ID del luogo, che sappiamo essere la sua chiave primaria. Una query come quella che segue, però, seppur corretta, potrebbe essere bloccata dal DBMS

```sql
SELECT l.nome,l.citta,count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
 GROUP BY l.ID
```

in quanto non è chiaro (almeno al DBMS) se nome e città, citati nella SELECT, siano legati all'ID usato per il raggruppamento. La soluzione è inserire anche questi due campi nella GROUP BY: noi sappiamo che questo non cambierà il partizionamento, e il DBMS "è tranquillo" e ci permette di mandarli in output.

```sql
SELECT l.nome,l.citta,count(*) AS numero_partite,
  sum(p.punti_squadra_1 + p.punti_squadra_2) AS punti_totali
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
 GROUP BY l.ID,l.nome,l.citta
```

### "Classifica marcatori 2020"

Procedendo per gradi, sappiamo sicuramente come estrarre la lista dei marcatori delle partite del campionato 2020:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno = 2020 AND (c.anno=f.anno)
```

in questo caso avremo un record con nome, cognome e squadra pe ogni punto segnato. *Nota: se volessimo considerare gli autogol (ad esempio impostando a un valore negativo il campo punti dei record della tabella segna), potremmo filtrarli da questa classifica (gli autogol non contano nelle classifiche dei marcatori!) inserendo il filtro e.punti\>0.*

Possiamo quindi raggruppare i record in base al giocatore (e alla relativa squadra):

```sql
SELECT g.nome, g.cognome, s.nome AS squadra
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno = 2020 AND (c.anno=f.anno) AND e.punti>0
 GROUP BY g.ID, g.nome, g.cognome, s.nome
```

...e contare quanti punti segnati ci sono in ciascuna partizione:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, sum(e.punti) AS punti
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno = 2020 AND (c.anno=f.anno) AND e.punti>0
 GROUP BY g.ID, g.nome, g.cognome, s.nome
```

infine, per ottenere una vera classifica, la ordiniamo per punti (colonna calcolata):

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, sum(e.punti) AS punti
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno = 2020 AND (c.anno=f.anno) AND e.punti>0
 GROUP BY g.ID, g.nome, g.cognome, s.nome
 ORDER BY punti DESC
```

..e per essere precisi, definiamo anche come ordinare tra loro i giocatori a pari punti:

```sql
SELECT g.nome, g.cognome, s.nome AS squadra, sum(e.punti) AS punti
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno = 2020 AND (c.anno=f.anno) AND e.punti>0
 GROUP BY g.ID, g.nome, g.cognome, s.nome
 ORDER BY punti DESC, g.cognome ASC, g.nome ASC, s.nome ASC
```

### "Calcolo del risultato di una partita (a partire dai punti segnati)"

Modificando la query già vista, possiamo estrarre e contare i punti segnati (indipendentemente dal giocatore) in una specifica partita: basterà fissare l'ID della partita e raggruppare solo per squadra:

```sql
SELECT s.nome AS squadra, sum(e.punti) AS punti
 FROM segna e
  JOIN giocatore g ON (e.ID_giocatore = g.ID)
  JOIN formazione f ON (f.ID_giocatore = g.ID)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE p.ID = 1 AND (c.anno=f.anno)
 GROUP BY s.ID, s.nome
```

Tuttavia, la query di cui sopra non è ottimizzata, in quanto coinvolge la tabella giocatore che non ci serve più (non stampiamo i nomi dei giocatori). È possibile quindi rivedere la catena dei JOIN escludendo la tabella giocatore:

```sql
SELECT s.nome AS squadra, sum(e.punti) AS punti
 FROM segna e
  JOIN formazione f ON (f.ID_giocatore = e.ID_giocatore)
  JOIN squadra s ON (f.ID_squadra = s.ID)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE p.ID = 1 AND (c.anno=f.anno)
 GROUP BY s.ID, s.nome
```

Nota: se in questo caso volessimo prendere in considerazione gli *autogol*, che sono a tutti gli effetti gol da assegnare alla squadra avversaria, dovremmo agire in maniera più "furba". Infatti, nel caso di un autogol, i punti vanno assegnati all'altra squadra in partita, non a quella a cui appartiene il giocatore che lo segna! Gestire questo caso può portare a spezzare in due la query creando delle sotto-query. Tuttavia, volendo conservare il più possibile della formulazione compatta che abbiamo visto finora, possiamo usare un "trucco" e scrivere la query che segue:

```sql
SELECT s.nome AS squadra, sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (f.ID_giocatore = e.ID_giocatore)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN squadra s ON (s.ID =
if(e.punti<0,if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1),f.ID_squadra))
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE p.ID = 1 AND (c.anno=f.anno)
 GROUP BY s.ID, s.nome
```

Il trucco qui consiste nel sostituire l'espressione del JOIN con la squadra, che a tutti gli effetti ci restituisce, per ogni punto segnato, il nome e l'ID della squadra da usare per il calcolo del punteggio, con un'espressione condizionale complessa, che ovviamente renderà più "pesante" il JOIN, ma realizza nella maniera più semplice quanto desideriamo. In particolare, inseriamo nel JOIN la squadra citata dalla formazione (come nel caso base) se i punti sono
positivi, altrimenti confrontiamo la squadra a cui appartiene il giocatore (f.ID_squadra) con quelle in partita (p.ID_squadra_1 e p.ID_squadra_2) e inseriamo l'altra squadra. 
In questo modo, nel JOIN realizzato, indipendentemente da quanto riportato dalla formazione, la squadra inserita sarà quella a vantaggio della quale è stato segnato il punto, 
e il resto della query (che raggruppa in base alla squadra) potrà rimanere identico, a patto che si sommi il valore assoluto (abs) dei punti, per eliminare il segno meno nel caso degli autogol.

## Condizioni sui gruppi (HAVING)

### "I punti totali segnati, per il campionato 2020, nei luoghi in cui si è giocata più di una partita"

Si tratta di una piccola variante alla query già vista in precedenza.

Se dobbiamo imporre una condizione filtrante NON sui record singoli, MA su funzioni calcolate sulle partizioni (gruppi), non possiamo inserirla nella clausola WHERE (che viene eseguita prima della GROUP BY, quindi lavora sui record), ma in una nuova clausola, HAVING, che viene dopo il raggruppamento:

```sql
SELECT l.nome,l.citta,
  sum(p.punti_squadra_1+p.punti_squadra_2) AS punti
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
 WHERE c.anno=2020
 GROUP BY l.ID, l.nome, l.citta
 HAVING count(*)>1
```