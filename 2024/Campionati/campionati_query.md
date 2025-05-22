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


### "Le partite in cui si sono segnati più punti in totale (versione corretta con sotto-query e pseudo-calcolo del massimo)"

Possiamo usare le sotto-query in maniera creativa per riscrivere una possibile versione corretta di una query mostrata in precedenza.
Infatti, possiamo calcolare il *massimo* numero di punti totali segnati in tutte le partite usando opportunamente le clausole ORDER BY e LIMIT:

```sql
SELECT (p2.punti_squadra_1+p2.punti_squadra_2) AS punti 
 FROM partita p2 
 ORDER BY punti 
 DESC LIMIT 1
```

Essendo quella appena scritta una query *singleton*, possiamo confrontarne il valore con i punti totali segnati in tutte le partite ed estrarre solo quelle
in cui tale numero è esattamente il massimo:

```sql
SELECT *, (p1.punti_squadra_1+p1.punti_squadra_2) AS punti
 FROM partita p1
 WHERE (p1.punti_squadra_1+p1.punti_squadra_2) = 
 (SELECT (p2.punti_squadra_1+p2.punti_squadra_2) AS punti FROM partita p2 ORDER BY punti DESC LIMIT 1)
```

ed avremo quindi le partite in cui il numero totale di punti segnati corrisponde al massimo assoluto tra tutte le partite.


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

### "Le partite in cui si sono segnati più punti in totale (versione corretta con sotto-query e operatore ALL)"

Abbiamo già dato una soluzione corretta per questa query, ma potremmo volerne formulare una alternativa che non usa la
clausola non-standard LIMIT, ad esempio.

Potremmo allora selezionare le partite il cui punteggio totale è *maggiore o uguale a quello di tutte le altre partite*:

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
  (SELECT s.ID FROM squadra s WHERE s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila") 
  AND g.ID = f.ID_giocatore
 ORDER BY f.numero ASC
```

In realtà, la stessa cosa si può ottenere senza la sotto query, facendo un JOIN con squadra e filtrando in base alla squadra selezionata:

```sql
SELECT f.numero, g.nome, g.cognome
 FROM formazione f, giocatore g, squadra s
 WHERE f.anno=2020 AND s.nome = "L'Aquila Calcio" AND s.citta="L'Aquila" 
  AND g.ID = f.ID_giocatore AND f.ID_squadra = s.ID
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

Da notare che qui abbiamo usato COUNT(\*) nella clausola HAVING per *contare le partite in ciascun gruppo di record generato dalla GROUP BY* in base 
al loro luogo di svolgimento. 

Tuttavia, se avessimo voluto scrivere questa query *senza utilizzare i dati ridondanti punti_squadra_1 e punti_squadra_2*,
ma ricalcolando "al volo" i punti segnati in base al contenuto della tabella *segna*, come abbiamo fatto in un esempio precedente, avremmo potuto scrivere

```sql
SELECT l.nome,l.citta,
  sum(e.punti) AS punti
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
  JOIN segna e ON (e.ID_partita = p.ID)
 WHERE c.anno=2020
 GROUP BY l.ID, l.nome, l.citta
 HAVING count(*)>1
```

...il che è SBGLIATO, perchè in questo caso ogni gruppo non conterrà più uno e un solo record per partita, ma a causa del JOIN con *segna* ci potranno essere 
più record per la stessa partita, oppure nessuno se la partita è finita zero e zero. Per contare correttamente quante partite sono incluse in ciascun gruppo, in questo caso dovremo scrivere

```sql
SELECT l.nome,l.citta,
  sum(e.punti) AS punti
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN luogo l ON (l.ID=p.ID_luogo)
  LEFT JOIN segna e ON (e.ID_partita = p.ID)
 WHERE c.anno=2020
 GROUP BY l.ID, l.nome, l.citta
 HAVING count(DISTINCT p.ID)>1
```

Da notare che abbiamo usato un LEFT JOIN per fare in modo che ciascuna partita appaia almeno una volta, anche se non si aggancia ad alcun record di *segna*,
e abbiamo sostituito il COUNT(\*) con un conteggio degli *ID* distinti delle partite presenti nel gruppo.

### "Il numero di squadre in cui ciascun giocatore ha giocato tra il 2015 e il 2020"

Sappiamo facilmente estrarre tutte le formazioni in cui i giocatori hanno giocato

```sql
SELECT g.nome, g.cognome, s.nome, f.anno
 FROM giocatore g
  JOIN formazione f ON (g.ID=f.ID_giocatore)
  JOIN squadra s ON (s.ID=f.ID_squadra)
 WHERE f.anno between 2015 AND 2020
```

possiamo partizionare i risultati rispetto ai giocatori distinti, quindi contare:

```sql
SELECT g.nome, g.cognome, count(*) AS squadre
 FROM giocatore g
  JOIN formazione f ON (g.ID=f.ID_giocatore)
 WHERE f.anno between 2015 AND 2020
 GROUP BY g.ID, g.nome, g.cognome
```

Da notare che abbiamo rimosso la tabella squadra dalla query (assieme al relativo JOIN) in quanto non ci interessa più avere in output il nome di ciascuna squadra, ma solo il numero di formazioni/squadre, che è deducibile dalla sola tabella formazione. Tuttavia, questa query riporta il numero di formazioni in cui ciascun giocatore è stato inserito. Due formazioni diverse possono essere relative alla stessa squadra! Dobbiamo allora contare il numero di squadre distinte che compaiono nelle formazioni associate a ciascun giocatore:

```sql
SELECT g.nome, g.cognome, count(DISTINCT f.ID_squadra) AS squadre
 FROM giocatore g
  JOIN formazione f ON (g.ID=f.ID_giocatore)
 WHERE f.anno between 2015 AND 2020
 GROUP BY g.ID, g.nome, g.cognome
```

### "I giocatori che hanno cambiato squadra tra il 2015 e il 2020"

Volendo estrarre i giocatori che hanno cambiato squadra, cioè quelli che hanno giocato in più di una squadra, basta basarsi sulla query precedente e spostare la count nella clausola HAVING con un opportuno filtro:

```sql
SELECT g.nome, g.cognome
 FROM giocatore g
  JOIN formazione f ON (g.ID=f.ID_giocatore)
 WHERE f.anno between 2015 AND 2020
 GROUP BY g.ID, g.nome, g.cognome
 HAVING count(DISTINCT f.ID_squadra)>1
```

# Sotto-query avanzate

## Operatore EXISTS

### "I giocatori che hanno segnato almeno un punto nel 2020"

Partiamo facendoci restituire tutti i giocatori che hanno segnato in una partita del 2020:

```sql
SELECT g.nome, g.cognome, p.ID
 FROM giocatore g
  JOIN segna e ON (g.ID=e.ID_giocatore)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

Se selezioniamo solo il nome del giocatore, e filtriamo i duplicati, otteniamo il risultato richiesto:

```sql
SELECT DISTINCT g.nome, g.cognome
 FROM giocatore g
  JOIN segna e ON (g.ID=e.ID_giocatore)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

La stessa cosa poteva essere fatta senza la DISTINCT usando un raggruppamento: basta raggruppare in base al giocatore e poi estrarre il nome e cognome

```sql
SELECT g.nome, g.cognome
 FROM giocatore g
  JOIN segna e ON (g.ID=e.ID_giocatore)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
 GROUP BY g.ID, g.nome, g.cognome
```

Tuttavia, va notato che *il raggruppamento non è un'alternativa alla DISTINCT nei casi in cui si vogliano eliminare i duplicati dal risultato di una query* sebbene in molti
casi, come quello appena visto, il risultato sia lo stesso. 

Il raggruppamento è un'operazione più onerosa e con una serie di vincoli e implicazioni, quindi *non deve assolutamente essere introdotto se non quando si debbano utilizzare degli operatori aggregati*. Ad esempio, avrebbe avuto senso usarlo se avessimo voluto rendere esplicita la condizione "almeno un punto" tramite la clausola HAVING. Tale formulazione sarebbe diventata in ogni caso necessaria se avessimo voluto estrarre i giocatori che hanno segnato almeno 2 punti, ad esempio:

```sql
SELECT g.nome, g.cognome
 FROM giocatore g
  JOIN segna e ON (g.ID=e.ID_giocatore)
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
 GROUP BY g.ID, g.nome, g.cognome
 HAVING sum(abs(e.punti))>=2
```

Tornando alla query richiesta (almeno un punto), potevamo ottenere lo stesso risultato anche con una sotto-query, scrivendo una query del tipo "restituisci un giocatore se esiste un goal da lui segnato in una partita del 2020". Si tratta di usare la query iniziale (giocatori che hanno segnato 2020) come sotto-query, filtrandola rispetto a uno specifico giocatore e verificando se restituisce almeno un record:

```sql
SELECT g.nome, g.cognome
 FROM giocatore g
 WHERE EXISTS(SELECT *
 FROM segna e
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND e.ID_giocatore = g.ID)
```

Notate come la sotto-query lavora sul record del giocatore proveniente dalla query esterna (attraverso il campo g.ID).

### "I giocatori che non hanno segnato nel 2020"

Mentre la query precedente poteva essere efficacemente (e preferibilmente) risolta con JOIN e DISTINCT, questa è semplicissima da risolvere con l'EXISTS, basta negarlo:

```sql
SELECT g.nome, g.cognome
 FROM giocatore g
 WHERE NOT EXISTS(SELECT *
 FROM segna e
  JOIN partita p ON (e.ID_partita = p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND e.ID_giocatore = g.ID)
```

mentre realizzarla senza EXISTS richiederebbe una struttura molto più complessa (ad esempio una differenza insiemistica, che però non è supportata da molti DBMS come MySQL).

## Sotto-query nella clausola FROM

### "A che minuto viene segnato il primo punto in ogni partita del campionato 2020?"

Per cominciare, sappiamo come estrarre tutti i punti segnati in una certa partita:

```sql
SELECT *
 FROM segna e
 WHERE e.ID_partita =1
```

...e quindi calcolare il minuto minimo tra i punti:

```sql
SELECT min(e.minuto)
 FROM segna e
 WHERE e.ID_partita =1
```

Una prima soluzione potrebbe essere quindi quella di elencare tutte le partite e associare a ciascuna il minuto del primo punto segnato con una sotto query correlata:

```sql
SELECT p.ID, s1.nome AS sq1, s2.nome AS sq2,
  (SELECT min(e.minuto) FROM segna e WHERE e.ID_partita=p.ID) AS primo_goal
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s1 ON (s1.ID=p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID=p.ID_squadra_2)
 WHERE c.anno=2020
```

Notare che per le partite terminate zero a zero il minuto mostrato è null, il che è giusto, perché non ci sono punti da considerare.

Possiamo anche evitare la sotto query usando in maniera più "furba" l'aggregazione:

```sql
SELECT p.ID, s1.nome AS sq1, s2.nome AS sq2,
  min(e.minuto) AS primo_goal
 FROM partita p
  JOIN segna e ON (e.ID_partita=p.ID)
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s1 ON (s1.ID=p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID=p.ID_squadra_2)
 WHERE c.anno=2020
 GROUP BY p.ID, s1.nome, s2.nome
```

abbiamo cioè associato le partite con tutti i punti segnati, abbiamo quindi raggruppato in base alla partita, e in ciascuna partizione ottenuta abbiamo infine calcolato il minuto minimo.

Il problema è che con questa soluzione le partite terminate senza punti (zero a zero) non sono mostrate, neppure con un null come nel caso precedente, per effetto dei JOIN. Volendo avere un risultato del tutto identico a quello della query precedente, possiamo modificare la catena dei JOIN e introdurre in JOIN esterno prima della tabella segna:

```sql
SELECT p.ID, s1.nome AS sq1, s2.nome AS sq2,
  min(e.minuto) AS primo_goal
 FROM (partita p
   JOIN campionato c ON (p.ID_campionato = c.ID)
   JOIN squadra s1 ON (s1.ID=p.ID_squadra_1)
   JOIN squadra s2 ON (s2.ID=p.ID_squadra_2))
  LEFT JOIN segna e ON (e.ID_partita=p.ID)
 WHERE c.anno=2020
 GROUP BY p.ID, s1.nome, s2.nome
```

da notare che, per come sono composti i JOIN nella query precedente, non era strettamente necessario usare le parentesi nella clausola FROM per creare una sotto-espressione con cui fare LEFT JOIN: sarebbe bastato inserire il LEFT JOIN al posto del JOIN con *segna* nella query iniziale, senza variare in altro modo la composizione della clausola FROM. Tuttavia, l'uso delle parentesi è "protettivo" e rende più chiaro il risultato dell'intera espressione.

### "Il tempo medio di attesa prima che un punto venga segnato una partita del campionato 2020"

La query, in altre parole, ci chiede di calcolare la media sul minuto del primo punto segnato in ciascuna partita. Avendo già una query che calcola la lista dei minuti per i primi goal di sogni partita, possiamo usarla come sotto query, in questo caso nella clausola FROM

```sql
SELECT avg(pg.primo_goal) AS media_primo_goal
 FROM (
  SELECT min(e.minuto) AS primo_goal
   FROM partita p
    JOIN campionato c ON (p.ID_campionato = c.ID)
    JOIN segna e ON (e.ID_partita=p.ID)
   WHERE c.anno=2020
   GROUP BY p.ID
 ) AS pg
```

In questo caso la query, messa tra parentesi nella FROM, costituisce per SQL a tutti gli effetti una tabella (calcolata), a cui dobbiamo dare un alias (pg), e sulla quale possiamo effettuare altre operazioni (qui semplicemente la funzione aggregata avg sulla colonna primo_goal di tutti i record). Da notare che abbiamo anche semplificato la sotto-query eliminando i JOIN con la tabella squadra, perché in questo caso non dovevamo esterne i nomi.

### "La media punti segnati da ogni giocatore in una partita del campionato 2020"

Possiamo calcolare i punti segnati da ciascun giocatore in ciascuna partita del 2020 con un'aggregazione:

```sql
SELECT g.ID AS gioc, g.nome, g.cognome, p.ID AS part,
  sum(abs(e.punti)) AS segnati
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN segna e ON (e.ID_partita=p.ID)
  JOIN giocatore g ON (e.ID_giocatore=g.ID)
 WHERE c.anno=2020
 GROUP BY g.ID, p.ID, g.nome, g.cognome
```

e applicando la stessa soluzione già vista, cioè usando quella precedente come sotto query nella clausola FROM di un'altra query, otteniamo il risultato richiesto:

```sql
SELECT gpp.nome, gpp.cognome,
  avg(gpp.segnati) AS media_punti_partita
 FROM (
  SELECT g.ID AS gioc, g.nome, g.cognome, sum(abs(e.punti)) AS segnati
   FROM partita p
    JOIN campionato c ON (p.ID_campionato = c.ID)
    JOIN segna e ON (e.ID_partita=p.ID)
    JOIN giocatore g ON (e.ID_giocatore=g.ID)
   WHERE c.anno=2020
   GROUP BY g.ID, p.ID, g.nome, g.cognome
 ) AS gpp
 GROUP BY gpp.gioc
```

In questo caso la query più esterna è leggermente più complessa, perché esegue un nuovo raggruppamento, per distinguere tra loro i punti partita di ciascun giocatore. 

Tuttavia, questa soluzione è ambigua perchè potrebbe non rispettare completamente la specifica. Infatti stiamo calcolando *la media dei punti segnati da un giocatore nelle sole partite in cui ha segnato qualcosa*, visto che nella query interna il JOIN tra *partita*, *giocatore* e *segna* esclude i giocatori che non hanno segnato in quella partita. Riformuliamo quindi la nostra query, partendo da un primo passo più semplice. 

Cerchiamo per prima cosa **i giocatori che hanno partecipato a ciascuna partita del 2020**:

```sql
SELECT p.ID AS part, g.ID AS gioc, g.nome, g.cognome
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN formazione f ON (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2)
  JOIN giocatore g ON (g.ID = f.ID_giocatore)
 WHERE c.anno = 2020 AND (f.anno = c.anno)
 ORDER BY p.id, g.id;
```

tramite il JOIN facciamo in modo di associare a ciascuna *partita* del 2020 i giocatori che risultano appartenenti alla *formazione* 2020 (stesso anno del campionato) 
*di una delle due squadre coinvolte nella partita*. 

Adesso mettiamo nella query anche la tabella *segna* e calcoliamo **il numero di punti segnati in ciascuna partita del 2020 dai giocatori delle due formazioni partecipanti**:

```sql
SELECT p.ID AS part, g.ID AS gioc, g.nome, g.cognome,
  IF(SUM(ABS(e.punti)) IS NOT NULL,SUM(ABS(e.punti)),0) AS segnati
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN formazione f ON (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2)
  JOIN giocatore g ON (g.ID = f.ID_giocatore)
  LEFT JOIN segna e ON (e.ID_giocatore = g.ID AND e.ID_partita = p.ID)
 WHERE c.anno = 2020 AND (f.anno = c.anno)
 GROUP BY p.id, g.id, g.nome, g.cognome;
```

abbiamo usato un LEFT JOIN tra la struttura della FROM precedente e la tabella *segna* per fare in modo che tutte le coppie giocatore/partita appaiano nel risultato, eventualmente associate ai vari record di *segna* se quel giocatore ha segnato in quella partita (se ha segnato più volte, ci saranno più record per la stessa coppia giocatore/partita). A questo punto basta raggruppare per partita e giocatore e avremo il risultato voluto. Tuttavia, se un giocatore non ha segnato in una partita, l'espressione `SUM(ABS(e.punti))` varrebbe semplicemente `null`, quindi usiamo un'espressione IF per inserire uno zero in questi casi.

Infine, applicando sempre la stessa soluzione già vista, cioè usando quella precedente come sotto query nella clausola FROM di un'altra query, otteniamo il risultato richiesto:


```sql
SELECT gpp.nome, gpp.cognome, AVG(gpp.segnati) AS media_punti_partita
FROM (
 SELECT g.ID AS gioc, g.nome, g.cognome,
   IF(SUM(ABS(e.punti)) IS NOT NULL, SUM(ABS(e.punti)), 0) AS segnati
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN formazione f ON (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2)
  JOIN giocatore g ON (g.ID = f.ID_giocatore)
  LEFT JOIN segna e ON (e.ID_giocatore = g.ID AND e.ID_partita = p.ID)
  WHERE c.anno = 2020 AND (f.anno = c.anno)
  GROUP BY p.id , g.id , g.nome , g.cognome
 ) AS gpp
 GROUP BY gpp.gioc
```

## Sotto-query con le Common Table Expressions

Le Common Table Expression (CTE) sono una caratteristica SQL avanzata, disponibile in MySQL solo dalla versione 8, che permette di utilizzare le sotto-query
in modo più naturale, dando loro un nome e invocandole come una sorta di procedura.

Tecnicamente una CTE è una tabella temporanea di dati, costruita da una query e associata a un nome, che esiste nell'ambito di una singola istruzione e a cui è possibile fare riferimento all'interno di tale istruzione, anche più volte e anche in maniera ricorsiva (ma non ci occuperemo qui delle *query ricorsive*). 

Le CTE si dichiarano con la parola chiave WITH, scrivendo

```sql
WITH nome_1 AS (query_1), nome_2 AS (query_2)
query_principale
```

dove nella clausola FROM di *query_principale* si può fare riferimento a *nome_1* e *nome_2* (cioè alle tabelle risultanti da *query_1* e *query_2*) come fossero normali tabelle presenti nel database

### "A che minuto viene segnato il primo punto in ogni partita del campionato 2020?" (versione CTE)

```sql
WITH sub AS (
SELECT p.ID AS ID,s1.nome AS nome_s1,s2.nome AS nome_s2 
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s1 ON (s1.ID=p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID=p.ID_squadra_2)
 WHERE c.anno=2020
)
SELECT sub.ID, sub.nome_s1 AS sq1, sub.nome_s2 AS sq2,
 min(e.minuto) AS primo_goal
FROM sub LEFT JOIN segna e ON (e.ID_partita=sub.ID)
GROUP BY sub.ID, sub.nome_s1 , sub.nome_s2 ;
```

### "Il tempo medio di attesa prima che un punto venga segnato una partita del campionato 2020" (versione CTE)

```sql
WITH pg AS (
 SELECT min(e.minuto) AS primo_goal
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN segna e ON (e.ID_partita=p.ID)
 WHERE c.anno=2020
 GROUP BY p.ID
) 
SELECT avg(pg.primo_goal) AS media_primo_goal
FROM pg
```

### "La media punti segnati da ogni giocatore in una partita del campionato 2020" (versione CTE)

```sql
WITH gpp AS (
 SELECT g.ID AS gioc, g.nome, g.cognome,
   IF(SUM(ABS(e.punti)) IS NOT NULL, SUM(ABS(e.punti)), 0) AS segnati
  FROM partita p
   JOIN campionato c ON (p.ID_campionato = c.ID)
   JOIN formazione f ON (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2)
   JOIN giocatore g ON (g.ID = f.ID_giocatore)
   LEFT JOIN segna e ON (e.ID_giocatore = g.ID AND e.ID_partita = p.ID)
  WHERE c.anno = 2020 AND (f.anno = c.anno)
  GROUP BY p.id , g.id , g.nome , g.cognome
)
SELECT gpp.nome, gpp.cognome, AVG(gpp.segnati) AS media_punti_partita
 FROM gpp
 GROUP BY gpp.gioc
```

## Considerazioni di efficienza con le sotto-query

### "I punti classifica ottenuti in casa dalle squadre nel campionato 2020"

Supponiamo che la "squadra di casa" sia sempre la prima della partita (ID_squadra_1) e che alla squadra vincitrice di una partita vengano assegnati tre punti classifica, mentre in caso di pareggio a entrambe le squadre vada assegnato un punto.

La seguente query associa le partite del campionato 2020 con le squadre che hanno giocato in casa:

```sql
SELECT *
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID=p.ID_squadra_1)
 WHERE c.anno=2020
```

Possiamo quindi raggruppare per squadra, magari contando quante partite in totale sono state giocate in casa da quella squadra:

```sql
SELECT s.nome, count(*) AS numero_partite_casa
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID=p.ID_squadra_1)
 WHERE c.anno=2020
 GROUP BY s.ID, s.nome
```

A questo punto, confrontando tra di loro i punteggi riportati nella partita, e considerando che se punti_squadra_1 \> punti_squadra_2 allora la squadra di casa ha vinto, mentre se questi punti sono uguali allora le squadre hanno pareggiato, possiamo usare l'operatore IF di MySQL per calcolare i punti classifica assegnati alla squadra di casa in ogni partita, e quindi sommarli per ottenere il risultato desiderato:

```sql
SELECT s.nome, sum(
IF(p.punti_squadra_1>p.punti_squadra_2, 3,
  IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
  )) AS punti_classifica_in_casa
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID=p.ID_squadra_1)
 WHERE c.anno=2020
 GROUP BY s.ID, s.nome
```

allo stesso modo possiamo calcolare i punti classifica ottenuti fuori casa, semplicemente considerando la ID_squadra_2 e i relativi punti segnati:

```sql
SELECT s.nome, sum(
IF(p.punti_squadra_1<p.punti_squadra_2, 3,
  IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
  )) AS punti_classifica_fuori_casa
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID=p.ID_squadra_2)
 WHERE c.anno=2020
 GROUP BY s.ID, s.nome
```

### "La classifica del campionato 2020"

Sappiamo già calcolare i punti ottenuti in casa e fuori casa da una specifica squadra, ad esempio per la squadra con ID=1 i punti fuori casa sono:

```sql
SELECT sum(
IF(p.punti_squadra_1<p.punti_squadra_2, 3,
  IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
  )) AS punti_classifica_fuori_casa
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_2=1
```

da notare che abbiamo eliminato il JOIN con squadra per maggiore efficienza, confrontando l'ID richiesto direttamente con ID_squadra_2. Possiamo allora usare queste due query come sotto query in un'unica SELECT che enumera le squadre e per ciascuna calcola e somma i punti in casa e fuori casa per avere i punti classifica finali:

```sql
SELECT s.nome, (
  (SELECT sum(IF(p.punti_squadra_1>p.punti_squadra_2, 3,
    IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
   ))
    FROM partita p
     JOIN campionato c ON (p.ID_campionato = c.ID)
    WHERE c.anno=2020 AND p.ID_squadra_1=s.ID
  ) + (SELECT sum(IF(p.punti_squadra_1<p.punti_squadra_2, 3,
    IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
   ))
    FROM partita p
     JOIN campionato c ON (p.ID_campionato = c.ID)
    WHERE c.anno=2020 AND p.ID_squadra_2=s.ID
  )) AS punti_classifica
 FROM squadra s
 ORDER BY punti_classifica DESC
```

Se guardate bene, la query principale (esterna) è una semplice SELECT s.nome, \<subquery\> AS punti_classifica FROM squadra s ORDER BY punti_classifica DESC. Tutta la complessità è nella \<subquery\> nidificata nella SELECT, che è a sua volta composta da due sotto query scalari sommate. In queste ultime abbiamo usato l'alias s1 per la tabella squadra, in modo da poter creare una relazione con la squadra della query esterna (s). Tuttavia, le due sotto query usano lo stesso alias s1, in quanto non si sovrappongono e non ci sono problemi di ambiguità.

C'è però un problema: la query di cui sopra enumera tutte le squadre, anche quelle che potenzialmente potrebbero non aver giocato nel 2020. In tal caso, vengono messe in classifica a zero punti. Questo non è del tutto corretto. Bisogna quindi limitare la query principale alle sole squadre che hanno giocato nel 2020. Un modo per sapere quali sono queste squadre è vedere se esiste (EXISTS) una partita del 2020 in cui la squadra figura come ID_squadra_1 o ID_squadra_2:

```sql
SELECT s.ID
 FROM squadra s
 WHERE EXISTS(SELECT *
  FROM partita p
   JOIN campionato c ON (p.ID_campionato = c.ID)
  WHERE c.anno=2020
  AND (s.ID=p.ID_squadra_1 OR s.ID=p.ID_squadra_2)
 )
```

Possiamo introdurre questa condizione nella nostra query principale, ottenendo:

```sql
SELECT s.nome, (
(SELECT sum(
IF(p.punti_squadra_1>p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_1=s.ID
) +
(SELECT sum(
IF(p.punti_squadra_1<p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_2=s.ID
)
) AS punti_classifica
 FROM squadra s
 WHERE EXISTS(
SELECT *
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
AND (s.ID=p.ID_squadra_1 OR s.ID=p.ID_squadra_2)
)
 ORDER BY punti_classifica DESC
```

Tuttavia, potremmo anche ottenere la lista delle squadre che hanno giocato una partita nel 2020 considerando la lista delle squadre che hanno giocato in casa:

```sql
SELECT ID_squadra_1
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

...e quella delle squadre che hanno giocato fuori casa:

```sql
SELECT ID_squadra_2
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
```

...unendole infine in un'unica lista. Come? Usando la UNION di SQL:

```sql
(SELECT ID_squadra_1 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020)
UNION
(SELECT ID_squadra_2 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020)
```

Da notare che in MySQL la UNION effettua automaticamente una DISTINCT, mentre potremmo avere tutti i record, anche non unici, scrivendo

```sql
(SELECT ID_squadra_1 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020)
UNION ALL
(SELECT ID_squadra_2 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020)
```

A questo punto è possibile usare la lista appena ottenuta con l'operatore IN all'interno di un'altra versione della query della classifica già realizzata:

```sql
SELECT s.nome, (
(SELECT sum(
IF(p.punti_squadra_1>p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_1=s.ID
) +
(SELECT sum(
IF(p.punti_squadra_1<p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_2=s.ID
)
) AS punti_classifica
 FROM squadra s
 WHERE s.ID in (
(SELECT ID_squadra_1 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
)
UNION
(SELECT ID_squadra_2 AS squadra
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020
)
)
 ORDER BY punti_classifica DESC
```

Quale query è migliore? Questa o quella con la EXIST già vista? Per rispondere, al di là della complessità delle due sotto query usate per determinare le squadre che hanno giocato, dobbiamo capire come queste vengono eseguite.

Nel caso della EXIST, la sotto query è correlata (tramite s.ID) con la query esterna, quindi la sotto query EXITS verrà eseguita una volta per ogni squadra considerata dalla query principale. Nella soluzione precedente, invece, la sotto query che calcola la lista usata con la IN è costante, nel senso che il suo valore è sempre lo stesso, indipendente dalla squadra considerata. In questo caso, quindi, l'interprete SQL calcolerà la sotto query solo una volta, con un enorme guadagno nel tempo complessivo!

Infine, possiamo ottenere gli ID delle squadre che hanno giocato (in casa o fuori casa) una partita del campionato 2020 anche in un terzo modo, senza usare la UNION e senza l'EXISTS, ma sfruttando in maniera "furba" il JOIN:

```sql
SELECT DISTINCT s.ID
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID = p.ID_squadra_1 OR s.ID=p.ID_squadra_2)
 WHERE c.anno=2020
```

Il trucco qui è stato quello di collegare le partite a entrambe le squadre coinvolte, usando un JOIN con una OR nella condizione. A questo punto, estraendo gli ID delle squadre associate alle partite tramite questo JOIN, avremo gli ID delle squadre che hanno giocato, in casa o fuori casa, tali partite. Potremmo quindi riscrivere la query principale sostituendo alla UNION questa sotto-query come secondo argomento dell'operatore IN:

```sql
SELECT s.nome, (
(SELECT sum(
IF(p.punti_squadra_1>p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_1=s.ID
) +
(SELECT sum(
IF(p.punti_squadra_1<p.punti_squadra_2,
3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)
))
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
 WHERE c.anno=2020 AND p.ID_squadra_2=s.ID
)
) AS punti_classifica
 FROM squadra s
 WHERE s.ID in
(SELECT DISTINCT s.ID
 FROM partita p JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID=p.ID_squadra_1 OR s.ID=p.ID_squadra_2)
 WHERE c.anno=2020
)
 ORDER BY punti_classifica DESC
```

L'efficienza di questa query è probabilmente simile a quella che usa la UNION, ma il testo è molto più compatto. Da notare che qui, nella sotto query, usiamo un alias (s) usato anche dalla query esterna. Questo non è un problema, perché semplicemente l'alias ri-dichiarato nella sotto query renderà invisibile (perché inutile) quello esterno.

Partendo da quest'ultima formulazione, però, possiamo eliminare del tutto le sotto query per dare un'ultima, compatta e performante soluzione alla query della classifica:

```sql
SELECT s.nome, sum(
IF(s.ID = p.ID_squadra_1,
IF(p.punti_squadra_1>p.punti_squadra_2, 3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0)),
IF(p.punti_squadra_1<p.punti_squadra_2, 3,
IF(p.punti_squadra_1=p.punti_squadra_2,1,0))
)) AS punti_classifica
 FROM partita p
  JOIN campionato c ON (p.ID_campionato = c.ID)
  JOIN squadra s ON (s.ID = p.ID_squadra_1 OR s.ID=p.ID_squadra_2)
 WHERE c.anno=2020
 GROUP BY s.ID,s.nome
 ORDER BY punti_classifica DESC
```

Il trucco qui è stato partire dalla query che seleziona le squadre associandole alle partite giocate in casa o fuori casa, che prima usavamo nell'operatore IN. A questo punto, raggruppando in base alla squadra (s.ID) avremo in ciascuna partizione le partite in cui quest'ultima ha giocato, in casa o fuori casa, cioè come ID_squadra_1 o ID_squadra_2. Basta quindi rendere l'IF più complesso, andando a vedere se la squadra è, per ciascuna partita, quella di casa (IF(s.ID = p.ID_squadra_1)) o fuori casa, in modo da confrontare i punti della partita in maniera opportuna e calcolare i punti classifica conseguenti.

# Viste

### "I marcatori di tutte le partite, nella forma "anno campionato, ID_partita, squadra_1 -- squadra_2, minuto, nome_giocatore (squadra_giocatore)"

La query è molto semplice da realizzare sulla base di quanto già visto:

```sql
SELECT c.anno AS anno_campionato, p.ID AS ID_partita,
concat(s1.nome, ' - ', s2.nome) AS descrizione_partita,
e.minuto AS minuto, concat(g.nome,' ',g.cognome,
' (',IF(f.ID_squadra=s1.ID,s1.nome,s2.nome),')') AS marcatore
 FROM campionato c
  JOIN partita p ON (c.ID = p.ID_campionato)
  JOIN squadra s1 ON (s1.ID = p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID = p.ID_squadra_2)
  JOIN segna e ON (e.ID_partita=p.ID)
  JOIN giocatore g ON (g.ID=e.ID_giocatore)
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore AND f.anno=c.anno)
 ORDER BY p.data asc, e.minuto asc
```

Qui abbiamo usato due "trucchi":

- inserire l'uguaglianza f.anno=c.anno direttamente nella condizione del JOIN con la tabella formazione, invece che in una clausola WHERE,

- evitare di fare un terzo JOIN tra la tabella squadra e quella formazione per determinare il nome della squadra del giocatore, in quanto questa deve essere una delle due squadre in partita, che sono già state associate con altri JOIN (s1 e s2), quindi basta usare l'operatore IF per decidere quale nome stampare.

Se volessimo usare più volte questa query come sotto query, riscriverla sarebbe complesso e renderebbe le query principali molto più lunghe. Possiamo allora creare una vista basata sulla query scrivendo:

```sql
CREATE VIEW svolgimento_campionati AS
SELECT c.anno AS anno_campionato, p.ID AS ID_partita,
concat(s1.nome, ' - ', s2.nome) AS descrizione_partita,
e.minuto AS minuto,
concat(g.nome,' ',g.cognome,
' (',IF(f.ID_squadra=s1.ID,s1.nome,s2.nome),')') AS marcatore
 FROM campionato c
  JOIN partita p ON (c.ID = p.ID_campionato)
  JOIN squadra s1 ON (s1.ID = p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID = p.ID_squadra_2)
  JOIN segna e ON (e.ID_partita=p.ID)
  JOIN giocatore g ON (g.ID=e.ID_giocatore)
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore AND f.anno=c.anno)
 ORDER BY p.data asc, e.minuto asc
```

In questo modo la definizione della query risulta memorizzata nel database ed è utilizzabile, tramite il nome assegnatole, come una normale tabella in altre query:

```sql
SELECT *
 FROM svolgimento_campionati;
```

```sql
SELECT *
 FROM svolgimento_campionati
 WHERE anno_campionato=2020;
```

```sql
SELECT sc.*,p.data
 FROM svolgimento_campionati sc
 JOIN partita p ON (p.ID=sc.ID_partita)
 WHERE anno_campionato=2020
```

Va sempre ricordato che la vista viene "sostituita" dalla query quando è utilizzata, quindi i dati presenti nella  relativa "tabella virtuale" sono sempre aggiornati sulla base  dei contenuti correnti del database.

## Viste per l'accesso programmato ai dati

Un altro uso delle viste può essere quello di limitare/personalizzare l'accesso ai dati in base all'utente che è connesso al DBMS. Ad esempio, possiamo creare una tabella derivata da giocatore che non espone dati sensibili come data e luogo di nascita sotto forma di vista:

```sql
CREATE VIEW giocatore_gdpr AS
 SELECT ID,nome,cognome
  FROM giocatore
```

In questo modo, potremmo assegnare (GRANT) a un certo utente i privilegi di SELECT su questa tabella piuttosto che su quella di origine (giocatore), permettendogli di usarla in altre query ma senza mai poter accedere ai dati sensibili. Ad esempio:

```sql
REVOKE SELECT ON campionato.giocatore FROM 'app'@'localhost';
GRANT SELECT ON campionato.giocatore_gdpr TO 'app'@'localhost';
```

## Snapshot (viste congelate)

Se invece di *salvare una query* in una vista, volete invece creare uno *snapshot* di quella vista dati, cioè *"congelare" i dati al momento della creazione dello snapshot* , potete creare una tabella (*non una vista*) e riversarvi i dati generati dalla query al momento della creazione dello snapshot.

In questo caso, MySQL ha un'istruzione molto comoda: la CREATE TABLE ... AS ... crea una tabella adatta ad ospitare i risultati di una query e la popola con i dati restituiti dalla query stessa.

```sql
CREATE TABLE svolgimento_campionati_snapshot_20210519 AS
SELECT c.anno AS anno_campionato, p.ID AS ID_partita,
concat(s1.nome, ' - ', s2.nome) AS descrizione_partita,
e.minuto AS minuto,
concat(g.nome,' ',g.cognome,
' (',IF(f.ID_squadra=s1.ID,s1.nome,s2.nome),')') AS marcatore
 FROM campionato c
  JOIN partita p ON (c.ID = p.ID_campionato)
  JOIN squadra s1 ON (s1.ID = p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID = p.ID_squadra_2)
  JOIN segna e ON (e.ID_partita=p.ID)
  JOIN giocatore g ON (g.ID=e.ID_giocatore)
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore AND f.anno=c.anno)
 ORDER BY p.data asc, e.minuto asc
```

Dopo aver eseguito questa istruzione, avrete nel database una nuova tabella con uno snapshot dei dati restituiti dalla query nell'istante della creazione. Ovviamente questi dati non saranno aggiornati automaticamente: se volete aggiornare lo snapshot dovrete cancellare e ricreare la relativa tabella.

# Procedure

### "Le formazioni di tutte le squadre in tutti gli anni di campionato"

Si tratta di una query molto semplice:

```sql
SELECT f.anno, f.ID_squadra, f.numero, g.nome, g.cognome
 FROM formazione f
  JOIN giocatore g ON (g.ID=f.ID_giocatore)
 ORDER BY f.anno asc, f.ID_squadra asc, f.numero asc
```

Potremmo memorizzarla sotto forma di vista, ma in SQL esiste anche un altro modo per "incorporare" le query all'interno di una logica più ampia, che ci permette di usarne i risultati per eseguire operazioni complesse, che solitamente avremmo rimesso ai programmi client della base di dati: le procedure.

## Definizione di procedure

*Attenzione: la sintassi delle procedure è molto DBMS-specifica, quindi gli esempi che vedremo di seguito funzionano con MySQL ma potrebbero non funzionare con altri DBMS.*

Possiamo ad esempio inserire la query come istruzione in una procedura:

```sql
DROP PROCEDURE IF EXISTS formazioni;
DELIMITER $
CREATE PROCEDURE formazioni()
BEGIN
 SELECT f.anno, f.ID_squadra, f.numero, g.nome, g.cognome
  FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
  ORDER BY f.anno asc, f.ID_squadra asc, f.numero asc;
END$
DELMITER ;
```

Attenzione: per evitare ambiguità tra il terminatore usato per separare le istruzioni all'interno della procedura e quello dello statement SQL CREATE PROCEDURE, modifichiamo temporaneamente quest'ultimo (impostandolo a $) usando il comando DELIMITER. Di seguito ometteremo questo comando negli esempi, ma considerate che è sempre necessario.

## Chiamata di procedure

Per chiamare una procedura si usa il comando CALL:

```sql
CALL formazioni()
```

Il risultato dipende dalla procedura. Se, come nel nostro caso, questa contiene un'istruzione-query, allora la chiamata ritorna i risultati della query (in particolare, dell'ultima query eseguita, nel caso ce ne fossero più d'una), proprio come se l'avessimo eseguita in maniera diretta.

## Procedure con parametri

### "La formazione di una specifica squadra per un dato anno"

Sappiamo bene come scrivere questa query, ma ora vorremmo memorizzarla nel database in modo da poterla invocare senza riscriverne l'intero codice. Non possiamo usare una vista, perché ci sono dei parametri (squadra e anno), e le viste non possono avere parametri. Possiamo però usare una procedura, perché quest'ultima può accettare parametri:

```sql
CREATE PROCEDURE formazione (idsquadra integer unsigned, anno smallint)
BEGIN
 SELECT f.numero, g.nome, g.cognome
  FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
  WHERE f.anno=anno AND f.ID_squadra=idsquadra
  ORDER BY f.numero asc;
END$
```

Da notare come i parametri della procedura, dichiarati come fossero colonne di una tabella, possono poi essere usati nella query.

A questo punto, la nuova procedura può essere chiamata scrivendo

```sql
CALL formazione(1,2020)
```

## Procedure e tabelle temporanee

Attenzione, però: una chiamata a procedura non si può usare come sotto query, quindi il risultato di cui sopra non si può riutilizzare direttamente per costruire una query più complessa. Un passibile escamotage in questo caso potrebbe essere quello di far creare alla procedura una tabella temporanea nel database con i risultati della query, invece di restituirli, e poi lavorare su questa tabella:

```sql
CREATE procedure formazione
(idsquadra integer unsigned, anno smallint)
BEGIN
 DROP TABLE IF EXISTS formazione_r;
 CREATE TEMPORARY TABLE formazione_r AS
 SELECT f.numero, g.nome, g.cognome
  FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
  WHERE f.anno=anno AND f.ID_squadra=idsquadra
  ORDER BY f.numero asc;
END$
```

La sintassi CREATE TEMPORARY TABLE crea una tabella che verrà rimossa alla chiusura della connessione al DBMS. A questo punto potremmo scrivere

```sql
CALL formazione(1,2020);
SELECT * FROM formazione_r;
```

## Costrutti condizionali: IF

### "La formazione di una specifica squadra per un dato anno o per tutti gli anni di campionato"

Si tratta in questo caso di DUE query distinte, anche se molto simili tra loro. Possiamo però inglobarle in una stessa procedura, usando il costrutto IF...THEN...ELSE per scegliere quale eseguire in base ai parametri passati:

```sql
CREATE PROCEDURE formazione (idsquadra integer unsigned, anno smallint)
BEGIN
 IF (anno is not null) THEN
 BEGIN
  SELECT f.numero, g.nome, g.cognome
   FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
   WHERE f.anno=anno AND f.ID_squadra=idsquadra
   ORDER BY f.numero asc;
 END;
 ELSE
 BEGIN
  SELECT f.anno, f.numero, g.nome, g.cognome
   FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
   WHERE f.ID_squadra=idsquadra
   ORDER BY f.anno asc, f.numero asc;
  END;
 END IF;
END$
```

In questo modo la procedura selezionerà quale query eseguire (restituendone i risultati) in base al valore nullo o non nullo del parametro anno:

```sql
CALL formazione(1,2020);
CALL formazione(1,null)
```

Nota bene: questo risultato avremmo potuto ottenerlo anche senza usare un'istruzione IF, che qui è sfruttata solo per poterne illustrare la sintassi, semplicemente creando una singola query più "intelligente":

```sql
CREATE PROCEDURE formazione
(idsquadra integer unsigned, anno smallint)
BEGIN
 SELECT f.anno, f.numero, g.nome, g.cognome
  FROM formazione f JOIN giocatore g ON (g.ID=f.ID_giocatore)
  WHERE (anno IS NULL OR f.anno=anno) AND f.ID_squadra=idsquadra
  ORDER BY f.anno asc, f.numero asc;
END$
```

L'astuzia qui è nell'espressione *(anno IS NULL OR f.anno=anno)* , che fa valutare il vincolo *f.anno=anno* solo se anno non è nullo. Tuttavia, con questa formulazione 
non siamo in grado di estrarre insiemi di colonne diversi in base alla modalità di interrogazione, cosa che invece facevamo facilmente nella procedura.

## Parametri di output

### "La squadra di appartenenza di un giocatore in un determinato anno"

Anche qui la query è banale, ma proviamo a incorporarla in una procedura:

```sql
CREATE PROCEDURE squadra_appartenenza
(idgiocatore integer unsigned, anno smallint)
BEGIN
 SELECT s.nome FROM squadra s
   JOIN formazione f ON (f.ID_squadra=s.ID)
  WHERE f.ID_giocatore=idgiocatore AND f.anno=anno;
END$
```

Chiamando questa procedura con

```sql
CALL squadra_appartenenza(1,2020)
```

avremmo in output un *singleton*, cioè una tabella con una sola riga e una sola colonna, contenente il nome della squadra. Esiste un modo più pratico di riusare questo valore senza passare per una tabella temporanea? In realtà ne esistono molteplici.

Come primo esempio, possiamo passare alla procedura un parametro di *output* (quelli finora passati erano tutti implicitamente solo di *input*, ma possiamo anche esplicitarlo):

```sql
CREATE PROCEDURE squadra_appartenenza
(IN idgiocatore integer unsigned, IN anno smallint,
OUT nome_squadra varchar(100))
BEGIN
 SET nome_squadra = (SELECT s.nome FROM squadra s JOIN formazione f ON
  (f.ID_squadra=s.ID) WHERE f.ID_giocatore=idgiocatore AND
  f.anno=anno);
END$
```

In questa procedura mostriamo anche come assegnare un valore a una variabile (in questo caso il parametro di output nome_squadra) usando il comando SET. Poiché la query è un sigleton, si può assegnare il suo valore a una variabile come fosse una qualsiasi espressione.

Nella chiamata a questo tipo di procedura, bisogna assicurarsi di passare una variabile al posto dei parametri di tipo OUT. Se la chiamata fosse fatta all'interno di un'altra procedura, potremmo usare delle variabili locali a questo scopo. Se invece chiamiamo la procedura dall'interprete, possiamo creare delle variabili temporanee prefissandone il come con una chiocciola (@):

```sql
CALL squadra_appartenenza(1,2020,@n)
```

Dopodiché possiamo usare la variabile @n in qualsiasi contesto:

```sql
SELECT @n
```

## Il costrutto SELECT INTO

Nella query precedente, possiamo anche assegnare il parametro di output nome_squadra usando una variante del comando SELECT utilizzabile solo nelle procedure e solo quando la query è di tipo singleton o riga (cioè ritorna una sola riga di risultati, con una o più colonne):

```sql
CREATE PROCEDURE squadra_appartenenza
(IN idgiocatore integer unsigned, IN anno smallint,
OUT nome_squadra varchar(100))
BEGIN
 SELECT s.nome
  FROM squadra s
   JOIN formazione f ON (f.ID_squadra=s.ID)
  WHERE f.ID_giocatore=idgiocatore AND f.anno=anno
 INTO nome_squadra;
END$
```

Questa speciale sintassi memorizza i valori di ciascuna colonna estratta dalla SELECT nelle rispettive variabili inserite nella clausola finale INTO.

## Dichiarazione e assegnamento di variabili

Come ulteriore variante, possiamo anche estrarre i dati con la query, memorizzarli in variabili locali e poi manipolarli per ottenere il risultato finale (anche se il codice che segue potrebbe essere riscritto più semplicemente con una singola query...)

```sql
CREATE PROCEDURE squadra_appartenenza
(IN idgiocatore integer unsigned, IN anno smallint,
OUT nome_squadra varchar(100))
BEGIN
 DECLARE citta varchar(100);
 DECLARE nome varchar(100);

 SELECT s.nome,s.citta
  FROM squadra s
   JOIN formazione f ON (f.ID_squadra=s.ID)
  WHERE f.ID_giocatore=idgiocatore AND f.anno=anno
 INTO nome, citta;

 SET nome_squadra = concat(nome,' (',citta,')');
END$
```

In questo esempio mostriamo anche come creare variabili locali alla procedura con il comando DECLARE.

# Funzioni

Possiamo riscrivere in maniera più naturale la procedura *squadra_appartenenza* come una funzione:

```sql
CREATE FUNCTION squadra_per( idgiocatore integer unsigned, anno smallint ) 
  RETURNS varchar(100) DETERMINISTIC
BEGIN
 RETURN (SELECT concat(s.nome,' (',s.citta,')')
  FROM squadra s JOIN formazione f ON (f.ID_squadra=s.ID)
  WHERE f.ID_giocatore=idgiocatore AND f.anno=anno);
END$
```

Usiamo come di consueto la parola chiave RETURN per restituire il risultato, in questo caso calcolato con un'unica query. Da notare che, nella definizione della funzione:

* I parametri possono essere di solo input.

* Dobbiamo dichiarare il tipo di ritorno con la parola chiave RETURNS dopo la lista parametri.

* In MySQL, le funzioni devono essere deterministiche, cioè devono restituire lo stesso risultato se applicate con gli stessi parametri sugli stessi dati. Questo è necessario per questioni di ottimizzazione e, a più basso livello, per aiutare il sistema di replicazione. Per questo motivo, dovete esplicitamente dichiarare DETERMINISTIC la funzione.

È possibile usare la funzione appena definita in qualsiasi contesto: in altre funzioni o procedure, oppure all'interno di una query, come nell'esempio seguente:

```sql
SELECT g.nome,g.cognome,squadra_per(g.ID,2020) AS squadra_2020
 FROM giocatore g;
```

### "Il numero di punti segnati da una squadra in una partita"

Si tratta di una variante di una query che abbiamo già usato in altri contesti:

```sql
SELECT sum(abs(e.punti))
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE (f.anno = c.anno) AND (p.ID=X) AND (f.ID_squadra=Y)
```

Dove X e Y sono gli ID della partita e della squadra che ci interessano. 

Ancora una volta, volendo considerare gli autogol, potremmo scrivere come segue:

```sql
SELECT sum(abs(e.punti))
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE (f.anno = c.anno) AND (p.ID=X) AND 
  ((e.punti<0 AND f.ID_squadra<>Y) 
  OR (e.punti>=0 AND f.ID_squadra=Y))
```

In questo caso, verifichiamo che l'ID della squadra nella formazione sia quello richiesto per i punti normali e sia diverso da quello richiesto per gli autogol (basta dire "diverso", visto che nella partita ci sono solo due squadre...). *Tuttavia, per limitare la complessità del codice, negli esempi che seguono useremo la versione senza questa variante.*

Vogliamo trasformare questa query in una funzione, in modo da poterla rendere veramente parametrica:

```sql
CREATE FUNCTION punti_in_partita(
idpartita integer unsigned, idsquadra integer unsigned)
  RETURNS integer DETERMINISTIC
BEGIN
 RETURN (SELECT sum(abs(e.punti))
  FROM segna e
   JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
   JOIN partita p ON (p.ID = e.ID_partita)
   JOIN campionato c ON (c.ID = p.ID_campionato)
  WHERE (f.anno = c.anno) AND (p.ID=idpartita)
 AND (f.ID_squadra=idsquadra));
END$
```

Potremmo ad esempio usare questa funzione per ricalcolare i risultati di una partita e confrontarli con quelli inseriti nei campi della tabella partita:

```sql
SELECT concat(s1.nome,' - ', s2.nome) AS squadre,
p.punti_squadra_1, p.punti_squadra_2,
punti_in_partita(p.ID,p.ID_squadra_1) AS punti_1_calcolati,
punti_in_partita(p.ID,p.ID_squadra_2) AS punti_2_calcolati
 FROM partita p
  JOIN squadra s1 ON (s1.ID=p.ID_squadra_1)
  JOIN squadra s2 ON (s2.ID=p.ID_squadra_2)
```

# Codifica della logica di manipolazione dei dati tramite procedure e funzioni

Spesso la struttura di un database è tale che una semplice istruzione DML come INSERT o UPDATE non è sufficiente per aggiungere o modificare i dati in maniera corretta. In questi casi, può essere utile predisporre delle procedure o delle funzioni, richiamabili in maniera più intuitiva dall'utente, che si occupano di effettuare tutti i controlli e le operazioni necessarie a implementare la funzionalità richiesta. Vediamo alcuni esempi.

### "Inserisci una nuova squadra"

Nel primo caso, la procedura si limita a effettuare una banale INSERT:

```sql
CREATE PROCEDURE aggiungi_squadra(
nome varchar(50), citta varchar(20))
BEGIN
 INSERT INTO squadra(nome,citta) VALUES(nome,citta);
END$
```

Per inserire una squadra, l'utente potrà chiamare la procedura:

```sql
CALL aggiungi_squadra("SquadraNuova1","Roma")
```

Ovviamente qui la procedura non fa nulla di eccezionale, ma nasconde comunque la logica della INSERT e la struttura della tabella squadra, che nel tempo potrebbero anche cambiare. Possiamo renderla un po' più utile restituendo l'ID auto generato della squadra appena inserita: in questo caso è più opportuno creare una funzione:

```sql
CREATE FUNCTION aggiungi_squadra(
nome varchar(50), citta varchar(20))
RETURNS integer unsigned DETERMINISTIC
BEGIN
 INSERT INTO squadra(nome,citta) VALUES(nome,citta);
 RETURN last_insert_id();
END$
```

Dopo aver effettuato la INSERT, restituiamo il nuovo ID auto generato per la squadra, ottenuto tramite la funzione *last_insert_id.*

### "Cerca un arbitro e restituisci la sua chiave. Se non esiste ancora, crealo"

Vogliamo realizzare una funzione che ritorna la chiave di un arbitro dati il suo nome e cognome oppure, se l'arbitro non esiste, lo crea e ne restituisce la nuova chiave auto-generata:

```sql
CREATE FUNCTION cerca_aggiungi_arbitro(_nome varchar(50), _cognome varchar(100))
RETURNS integer unsigned DETERMINISTIC
BEGIN
 DECLARE aid integer unsigned;

 SELECT a.ID 
 FROM arbitro a 
 WHERE a.nome=_nome AND a.cognome=_cognome
 INTO aid;

 IF (aid IS NULL) THEN
 BEGIN
  INSERT INTO arbitro(nome,cognome) VALUES(_nome,_cognome);
  RETURN last_insert_id();
 END;
 ELSE
 BEGIN
  RETURN aid;
 END;
 END IF;
END$
```

La funzione prima prova a cercare l'arbitro tramite i suoi dati, e se non lo trova lo inserisce, quindi ritorna la chiave del record trovato o appena inserito.

Scrivendo quindi

```sql
SELECT cerca_aggiungi_arbitro("Nome","Cognome")
```

avremo in output la chiave dell'arbitro, e ci assicureremo contemporaneamente che sia presente nel nostro database.

### "Cerca una squadra e restituisci la sua chiave. Se non esiste ancora, creala"

Questa funzione ha la stessa logica della precedente ma, considerate le differenze tra la tabella squadra e quella arbitro, lavora in modo più complesso:

```sql
CREATE FUNCTION cerca_aggiungi_squadra(
  _nome varchar(50), _citta varchar(100))
  RETURNS integer unsigned DETERMINISTIC
BEGIN
 DECLARE idsquadra integer unsigned;

 SELECT s.ID FROM squadra s
  WHERE s.nome=_nome AND s.citta=_citta
 INTO idsquadra;

 IF (found_rows()=0) THEN
 BEGIN
  INSERT INTO squadra(nome,citta) VALUES(_nome,_citta);
  RETURN last_insert_id();
 END;
 ELSE
 BEGIN
  RETURN idsquadra;
 END;
 END IF;
END$
```

Per prima cosa la funzione cerca la squadra in base alla coppia nome e città (che sappiamo essere UNIQUE) e assegna il suo ID a una variabile. A questo punto, viene usata la funzione *found* _*rows* , che restituisce il numero di righe individuate dalla query immediatamente precedente, per capire se la squadra cercata esiste (*found_rows()=1* ) oppure no (*found_rows()=0* ). Nel primo caso si restituisce semplicemente l'ID individuato. Nel secondo, si effettua una INSERT e poi si restituisce il nuovo ID auto generato per la squadra, ottenuto tramite la funzione *last_insert_id.*

Se effettuiamo quindi le due chiamate che seguono sul database creato finora

```sql
SELECT cerca_aggiungi_squadra("L'Aquila Calcio","L'Aquila");
SELECT cerca_aggiungi_squadra("SquadraNuova2","Roma")
```

Nel primo caso avremo l'ID di una squadra preesistente, mentre nel secondo aggiungeremo una nuova squadra.

### "Aggiungi una nuova partita (completa del relativo arbitro)"

Una query del genere può richiedere vari passaggi, soprattutto se vogliamo inserire, assieme alla partita, anche il suo arbitro (*che supponiamo sia solo*). Infatti in questo caso dovremo inserire anche un record nella tabella direzione, che costituisce la relazione tra partita e arbitro. Possiamo realizzare questa operazione come funzione, restituendo l'ID della partita inserita, oppure come procedura, effettuando semplicemente l'inserimento dei dati oppure restituendo anche in questo caso l'ID della partita tramite un parametro OUT. Scegliamo questa seconda soluzione, che è più generica.

```sql
CREATE PROCEDURE aggiungi_partita(
_ID_squadra_1 integer unsigned, _ID_squadra_2 integer unsigned,
_data datetime,
_ID_campionato integer unsigned,
_ID_luogo integer unsigned,
_nome_arbitro_1 char(50),_cognome_arbitro_1 char(100),
OUT idpartita integer unsigned)
BEGIN
 DECLARE IDarbitro_1 char(16);

 INSERT INTO partita(data, ID_campionato, ID_luogo, ID_squadra_1, ID_squadra_2, punti_squadra_1, punti_squadra_2)
  VALUES (_data, _ID_campionato, _ID_luogo, _ID_squadra_1, _ID_squadra_2, 0, 0);

 SET idpartita = last_insert_id();

 SET IDarbitro_1 = cerca_aggiungi_arbitro(_nome_arbitro_1, _cognome_arbitro_1);

 INSERT INTO direzione(ID_arbitro,ID_partita)
  VALUES(IDarbitro_1,idpartita);
END$
```

Dopo aver inserito la partita e ottenuto il suo ID, che poi restituiremo tramite il parametro OUT, cerchiamo o aggiungiamo l'arbitro specificato usando la funzione *cerca_aggiungi_arbitro* già realizzata, che ci restituisce il suo ID, il quale verrà a sua volta utilizzato per inserire l'associazione tra la partita e l'arbitro nella tabella direzione. Basterà quindi invocare la procedura con

```sql
CALL aggiungi_partita(2, 3, "2020-12-13 12:12", 1, 1, "Pinco", "Pallino", @idp)
```

e poi, se vogliamo, leggere l'ID della partita appena creata:

```sql
SELECT @idp
```

Potremmo anche sfruttare la funzione *cerca_aggiungi_squadra* creata prima per rendere la nostra procedura ancor meno dipendente dagli ID interni della base di dati, ad esempio

```sql
CREATE PROCEDURE aggiungi_partita(
_nome_squadra_1 varchar(50), _citta_squadra_1 varchar(100),
_nome_squadra_2 varchar(50), _citta_squadra_2 varchar(100),
_data datetime,
_ID_campionato integer unsigned,
_ID_luogo integer unsigned,
_nome_arbitro_1 char(50),_cognome_arbitro_1 char(100),
OUT idpartita integer unsigned)
BEGIN
 DECLARE IDarbitro_1 char(16);
 DECLARE _ID_squadra_1 integer unsigned;
 DECLARE _ID_squadra_2 integer unsigned;

 SET _ID_squadra_1 = cerca_aggiungi_squadra(_nome_squadra_1, _citta_squadra_1);
 SET _ID_squadra_2 = cerca_aggiungi_squadra(_nome_squadra_2, _citta_squadra_2);

 INSERT INTO partita(data, ID_campionato, ID_luogo,
   ID_squadra_1, ID_squadra_2, punti_squadra_1, punti_squadra_2)
  VALUES (_data, _ID_campionato, _ID_luogo, _ID_squadra_1, _ID_squadra_2, 0, 0);

 SET idpartita = last_insert_id();

 SET IDarbitro_1 = cerca_aggiungi_arbitro(_nome_arbitro_1, _cognome_arbitro_1);

 INSERT INTO direzione(ID_arbitro,ID_partita)
  VALUES(IDarbitro_1,idpartita);
END$
```

Questa procedura cerca automaticamente gli ID delle squadre coinvolte e le crea se necessario (anche se quest'ultima operazione potrebbe essere pericolosa: se si cita una squadra inesistente, meglio segnalare l'errore piuttosto, come vedremo)

## Segnalare eccezioni

### "Inserisci un nuovo punto segnato da un giocatore in una partita"

Sappiamo che questo significa inserire un record nella tabella segna, ma con una procedura possiamo fare molto di più:

* Verificare che il giocatore sia in partita (cioè appartenga a una delle due squadre che la giocano).

* Aggiornare il punteggio nella tabella partita (cioè i campi calcolati punti_squadra_1 e punti_squadra_2).

In questo modo garantiremo la coerenza dei dati nel nostro database.

```sql
CREATE PROCEDURE aggiungi_punti( _ID_giocatore integer unsigned, 
 _ID_partita integer unsigned, _minuto smallint, _punti smallint)
BEGIN
 DECLARE IDsquadra_giocatore integer unsigned;
 DECLARE IDsquadra_1 integer unsigned;
 DECLARE IDsquadra_2 integer unsigned;

 SELECT f.ID_squadra
  FROM formazione f
  WHERE f.ID_giocatore=_ID_giocatore AND f.anno=(
   SELECT c.anno
    FROM campionato c JOIN partita p ON (c.ID=p.ID_campionato)
    WHERE p.ID=_ID_partita)
  INTO IDsquadra_giocatore;

 SELECT p.ID_squadra_1, p.ID_squadra_2
  FROM partita p
  WHERE p.ID=_ID_partita
 INTO IDsquadra_1,IDsquadra_2;

 IF (IDsquadra_giocatore=IDsquadra_1 OR IDsquadra_giocatore=IDsquadra_2) THEN
 BEGIN
  INSERT INTO segna(ID_giocatore,ID_partita,minuto,punti)
   VALUES (_ID_giocatore,_ID_partita,_minuto,_punti);

  UPDATE partita SET
   punti_squadra_1 = punti_squadra_1 +
    IF (_punti>0,
     IF(ID_squadra_1=IDsquadra_giocatore,_punti,0),
     IF(ID_squadra_2=IDsquadra_giocatore,-_punti,0)
    ),
   punti_squadra_2 = punti_squadra_2 +
    IF (_punti>0,
     IF(ID_squadra_2=IDsquadra_giocatore,_punti,0),
     IF(ID_squadra_1=IDsquadra_giocatore,-_punti,0)
    )     
   WHERE ID=_ID_partita;
 END;
 ELSE
 BEGIN
  SIGNAL SQLSTATE '45000'
  SET message_text="Il giocatore non è in partita";
 END;
 END IF;
END$
```

Per prima cosa cerchiamo in che squadra gioca il giocatore indicato nell'anno di campionato corrispondente alla partita specificata. Estraiamo quindi gli ID delle due quadre che giocano effettivamente quella partita. Se il giocatore appartiene a una delle due squadre in gioco, procediamo con l'inserimento del punto nella tabella segna e aggiorniamo il punteggio nella tabella partita usando un piccolo trucco: l'aggiornamento è eseguito su entrambi i campi punti_squadra_1 e punti_squadra_2, ma a questi viene sommato zero o il numero di punti richiesto uno in base a quale delle due squadre ha effettivamente segnato (e considerando anche gli autogol, cioè _punti \< 0), in modo tale che solo uno dei due venga effettivamente incrementato. Nel caso in cui, invece, il giocatore non sia effettivamente in partita, segnaliamo lo stato SQL 45000, che corrisponde a una generica condizione di errore utente, specificando un messaggio esplicativo.

Se quindi chiamiamo, sul database corrente

```sql
CALL aggiungi_punto(1,1,9,1)
```

Vedremo modificarsi il risultato della partita 1 come ci aspettiamo, mentre chiamando

```sql
CALL aggiungi_punto(4,1,19,1)
-- Error Code: 1644. Il giocatore non è in partita
```

Vedremo segnalato l'errore, e la base di dati non verrà aggiornata.

# Cursori

I cursori sono il modo con cui SQL (e la maggior parte dei linguaggi di programmazione) gestisce la lettura, all'interno del codice, dei risultati di una query generica, cioè che può potenzialmente restituire più righe e più colonne.

### "Controlla la coerenza tra il risultato calcolato di una partita e i punti segnati"

Quello che dobbiamo fare, per prima cosa, è ricalcolare le squadre che hanno segnato e il corrispondente numero di punti a partire dalla tabella segna. Questa query l'abbiamo già sviluppata in precedenza:

```sql
SELECT f.ID_squadra, sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=<ID> AND f.anno=c.anno
 GROUP BY f.ID_squadra;
```

ovviamente la query ha bisogno di un parametro *\<ID\>* per funzionare. Da notare che se una squadra non ha segnato non comparirà nel risultato di questa query.
Possiamo ovviamente scrivere una variante più complessa che prende in considerazione gli autogol:

```sql
SELECT if(e.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva, 
  sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=<ID> AND f.anno=c.anno
 GROUP BY squadra_effettiva;
```

In questo caso raggruppiamo su una colonna calcolata che, in base al tipo di punti, contiene l'ID della squadra a cui questo va effettivamente assegnato (la squadra per cui gioca chi ha segnato i punti, tranne nel caso in cui questi siano negativi, nel qual caso viene selezionata l'altra squadra nella partita).

A questo punto siamo pronti per scrivere la nostra procedura. La logica, dato l'ID di una partita, sarà la seguente:

1. estraiamo le squadre e i punti ad esse assegnati dalla tabella partita

2. ricalcoliamo chi ha segnato nella partita e quanti punti con la query appena vista, o meglio

   1. iteriamo sui record restituiti dalla query

   2. assegniamo a delle variabili i punti delle due squadre in partita

   3. se risulta aver segnato una squadra non in partita, segnaliamo l'errore e usciamo

   4. alla fine del ricalcolo, confrontiamo i punti ricalcolati con quelli estratti dalla tabella partita

      1. se i punti non corrispondono, segnaliamo l'errore e usciamo

      2. altrimenti restituiamo il messaggio "ok" e usciamo

```sql
CREATE FUNCTION controlla_partita(idpartita integer unsigned) 
 RETURNS varchar(100) DETERMINISTIC
BEGIN
 -- messaggio restituito
 DECLARE risultato varchar(100);
 -- query di calcolo del punteggio dalla tabella segna
 DECLARE punti CURSOR FOR SELECT if(e.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva, 
  sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=idpartita AND f.anno=c.anno
 GROUP BY squadra_effettiva;
 
 -- inizializzazione messaggio
 SET risultato = "ok";
 -- esecuzione query di ricalcolo
 OPEN punti;

 -- blocco di controllo
 controlli: BEGIN
 -- dati estratti dalla tabella partita
  DECLARE ids1 integer unsigned;
  DECLARE ids2 integer unsigned;
  DECLARE ps1 integer unsigned;
  DECLARE ps2 integer unsigned;
  -- punti calcolati dalla tabella segna
  DECLARE pcs1 integer unsigned;
  DECLARE pcs2 integer unsigned;
  -- risultato di base (se una squadra non ha segnato)
  SET pcs1=0;
  SET pcs2=0;
  -- informazioni presenti nella tabella partita
  SELECT ID_squadra_1,punti_squadra_1,ID_squadra_2,punti_squadra_2
   FROM partita
   WHERE ID=idpartita
  INTO ids1,ps1,ids2,ps2;

  -- blocco (nidificato) di ricalcolo
  ricalcolo: BEGIN
   -- variabili temporanee locali al blocco
   DECLARE ids integer unsigned;
   DECLARE pcs integer unsigned;

   -- handler per il cursore (fa uscire dal blocco di ricalcolo)
   DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;

   -- loop di lettura dei punti (ri)calcolati dalla query
   LOOP
    FETCH punti INTO ids,pcs;
    -- aggiornamento dei punti ricalcolati in base alla
    -- squadra corrispondente
    IF (ids=ids1) THEN SET pcs1 = pcs;
    ELSEIF (ids=ids2) THEN SET pcs2 = pcs;
    ELSE BEGIN
     -- la squadra che ha segnato non è in partita!
     SET risultato = concat("La squadra ",(SELECT nome FROM squadra WHERE ID=ids),
	  " ha segnato ",pcs," punti ma non risulta in partita");
     -- non eseguiamo altri controlli, usciamo direttamente
     LEAVE controlli;
     END;
    END IF;
   END LOOP;
  END; -- ricalcolo

  -- confrontiamo i punti assegnati con quelli ricalcolati
  IF (ps1<>pcs1) THEN SET risultato = concat("I punti della squadra ",
   (SELECT nome FROM squadra WHERE ID=ids1),
   " sono ",pcs1," ma la tabella partita riporta ", ps1);
  ELSEIF (ps2<>pcs2) THEN SET risultato = concat("I punti della squadra ",
   (SELECT nome FROM squadra WHERE ID=ids2),
   " sono ",pcs2," ma la tabella partita riporta ", ps2);
  END IF;
 END; -- controlli

 CLOSE punti; -- chiudiamo il cursore
 RETURN risultato;
END$
```

Da notare il modo in cui abbiamo nidificato i blocchi in modo che l'EXIT HANDLER del cursore e il comando LEAVE facciano saltare sempre nel punto giusto del codice, e che prima della RETURN venga eseguita sempre la CLOSE.

A questo punto possiamo eseguire i nostri controlli:

```sql
SELECT p.ID, controlla_partita(p.ID) AS risultato FROM partita p;
```

### "Imposta il punteggio finale di una partita in base ai punti in essa segnati"

In questo caso non vogliamo controllare se il punteggio finale attribuito a una partita è corretto, ma calcolarlo e impostarlo. La soluzione è una procedura molto simile a quella vista in precedenza per i controlli, che però alla fine aggiorna la partita.

```sql
CREATE PROCEDURE aggiorna_punti(idpartita integer unsigned)
BEGIN
 -- dati estratti dalla tabella partita
 DECLARE ids1 integer unsigned;
 DECLARE ids2 integer unsigned;
 -- punti calcolati dalla tabella segna
 DECLARE pcs1 integer unsigned;
 DECLARE pcs2 integer unsigned;
 -- query di calcolo del punteggio dalla tabella segna
 DECLARE punti CURSOR FOR SELECT if(e.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva, 
  sum(abs(e.punti)) AS punti
 FROM segna e
  JOIN formazione f ON (e.ID_giocatore = f.ID_giocatore)
  JOIN partita p ON (p.ID = e.ID_partita)
  JOIN campionato c ON (c.ID = p.ID_campionato)
 WHERE p.ID=idpartita AND f.anno=c.anno
 GROUP BY squadra_effettiva;
  
 -- esecuzione query di ricalcolo
 OPEN punti;
 -- risultato di base (nel caso in cui una squadra non avesse segnato)
 SET pcs1=0;
 SET pcs2=0;
 -- informazioni presenti nella tabella partita
 SELECT ID_squadra_1,ID_squadra_2
  FROM partita
  WHERE ID=idpartita
 INTO ids1,ids2;
 
 -- blocco di ricalcolo
 BEGIN
 -- variabili temporanee locali al blocco
  DECLARE ids integer unsigned;
  DECLARE pcs integer unsigned;
 -- handler per il cursore (fa uscire dal blocco di ricalcolo)
  DECLARE EXIT HANDLER FOR NOT FOUND BEGIN END;
 -- handler per l'errore (chiude il cursore e propaga la condizione)
  DECLARE EXIT HANDLER FOR SQLSTATE '45000'
  BEGIN
   CLOSE punti; -- chiudiamo il cursore
   RESIGNAL;
  END;
 -- loop di lettura dei punti (ri)calcolati dalla query
  LOOP
   FETCH punti INTO ids,pcs;
 -- aggiornamento dei punti ricalcolati in base alla squadra corrispondente
   IF (ids=ids1) THEN SET pcs1 = pcs;
   ELSEIF (ids=ids2) THEN SET pcs2 = pcs;
   ELSE BEGIN
 -- la squadra che ha segnato non è in partita!
    DECLARE messaggio varchar(100);
    SET messaggio = concat("La squadra ",(SELECT nome FROM squadra WHERE ID=ids),
	 " ha segnato ",pcs," punti ma non risulta in partita");
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = messaggio;
    END;
   END IF;
  END LOOP;
 END; -- ricalcolo
 
 CLOSE punti; -- chiudiamo il cursore
 -- aggiorniamo il punteggio della partita
 UPDATE partita
  SET punti_squadra_1=pcs1, punti_squadra_2=pcs2
  WHERE ID=idpartita;
END$
```

Da notare come anche in questa procedura ci blocchiamo nel caso in cui risulti aver segnato un giocatore non appartenente alle formazioni delle squadre in partita, ma in questo caso dopo aver chiuso il cursore propaghiamo l'errore verso l'esterno con la RESIGNAL.

Possiamo quindi calcolare e impostare il risultato finale di una partita chiamando

```sql
CALL aggiorna_punti(3)
```

# Trigger

## Trigger di controllo

Con i trigger possiamo eseguire diversi tipi di controllo sui dati, bloccando le operazioni nel caso in cui questi falliscano. Questo tipo di trigger è sempre posto BEFORE l'operazione.

### "Controlla automaticamente che la data della partita sia all'interno del campionato associato"

Immaginando che il campionato vada dal primo settembre dell'anno corrispondente al trenta giugno dell'anno successivo, possiamo scrivere il trigger che segue:

```sql
CREATE TRIGGER data_partita_valida BEFORE INSERT ON partita
FOR EACH ROW BEGIN
 DECLARE a smallint;
 SELECT anno FROM campionato WHERE ID =NEW.ID_campionato INTO a;
 IF NEW.data NOT BETWEEN str_to_date(concat(a,"-09-01"),"%Y-%m-%d")
  AND str_to_date(concat((a+1),"-06-30"),"%Y-%m-%d")
 THEN BEGIN
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = "Data non inclusa nel campionato";
  END;
 END IF;
END$
```

Notare come costruiamo le date di inizio e fine campionato come stringhe, e poi usiamo str_to_date per assicurarci che siano trasformate in un valido valore di tipo DATE di MySQL (in questo caso, visto come abbiamo costruito la stringa della data, non sarebbe strettamente necessario).

Con questo trigger, l'inserimento che segue verrebbe respinto, visto che il campionato con ID=1 si riferisce all'anno 2020:

```sql
INSERT INTO partita(data, ID_campionato, ID_luogo, ID_squadra_1, ID_squadra_2, punti_squadra_1, punti_squadra_2)
 VALUES ('2050-01-01 12:12:00', '1', '1', '2', '3', '0', '0')

-- Error Code 1644: Data non inclusa nel campionato
```

Tuttavia, il trigger non ci protegge dagli aggiornamenti che, dato un record corretto già inserito, modificano la sua data rendendola scorretta. Per questo motivo è opportuno creare anche un trigger BEFORE UPDATE che esegue lo stesso controllo. A questo punto, per non duplicare codice, possiamo modularizzare i trigger estraendo il controllo vero e proprio e inserendolo in una procedura di supporto:

```sql
CREATE PROCEDURE convalida_data
(idcampionato integer unsigned, data datetime)
BEGIN
 DECLARE a smallint;
 SELECT anno FROM campionato WHERE ID =idcampionato INTO a;
 IF data NOT BETWEEN str_to_date(concat(a,"-09-01"),"%Y-%m-%d")
  AND str_to_date(concat((a+1),"-06-30"),"%Y-%m-%d")
  THEN BEGIN
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = "Data non inclusa nel campionato";
  END;
 END IF;
END$
```

E poi scrivere semplicemente i due trigger

```sql
CREATE TRIGGER data_partita_valida_i BEFORE INSERT ON
partita
FOR EACH ROW BEGIN
 CALL convalida_data(NEW.ID_campionato,NEW.data);
END$
```

```sql
CREATE TRIGGER data_partita_valida_u BEFORE UPDATE ON partita
FOR EACH ROW BEGIN
 CALL convalida_data(NEW.ID_campionato,NEW.data);
END$
```

### "Controlla automaticamente che un giocatore inserito nella tabella segna appartenga alle formazioni delle squadre della relativa partita"

Sappiamo come calcolare con una semplice query le formazioni delle squadre, quindi possiamo scrivere altrettanto semplicemente il trigger che controlla se il giocatore è in queste formazioni, e in caso contrario genera un errore:

```sql
CREATE TRIGGER giocatore_valido BEFORE INSERT ON segna
FOR EACH ROW BEGIN
  IF NEW.ID_giocatore NOT IN (
  SELECT ID_giocatore
   FROM partita p
    JOIN campionato c ON (p.ID_campionato=c.ID)
    JOIN formazione f ON (f.anno=c.anno AND (f.ID_squadra = p.ID_squadra_1 OR f.ID_squadra = p.ID_squadra_2))
   WHERE p.ID=NEW.ID_partita)
 THEN
  SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT="Il giocatore non è in partita";
 END IF;
END$
```

A questo punto possiamo provare il funzionamento del trigger inserendo dei dati non validi nella tabella segna:

```sql
INSERT INTO segna(ID_giocatore, ID_partita, minuto, punti)
 VALUES (4, 1, 18, 1)

-- Error Code 1644: Il giocatore non è in partita
```

Anche in questo caso, il trigger andrebbe inserito anche BEFORE UPDATE per avere maggior sicurezza, ma omettiamo qui il codice per brevità.

## Trigger di calcolo

I trigger possono essere anche un comodo strumento per tenere aggiornati i valori dei campi calcolati, senza doversi preoccupare di inserire il relativo codice in tutte le procedure che possono determinarne il ricalcolo e impedire che i dati possano essere modificati direttamente. In questo caso, dovendo agire quando i dati sono stati effettivamente modificati, il trigger sarà sempre inserito AFTER l'evento corrispondente.

### "Ricalcola il punteggio finale di una partita ogni volta che viene inserito un punto nella tabella segna"

Se assumiamo di avere anche il trigger appena realizzato, che controlla BEFORE INSERT la validità del giocatore e quindi del record da inserire, possiamo assumere in un trigger AFTER INSERT che tutti i dati siano coerenti e procedere senza ulteriori controlli.

```sql
CREATE TRIGGER aggiorna_punti_i AFTER INSERT ON segna
FOR EACH ROW BEGIN
 DECLARE s integer unsigned;
 
 SELECT if(NEW.punti<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva
  FROM formazione f 
   JOIN partita p  
   JOIN campionato c ON (c.ID = p.ID_campionato)
  WHERE p.ID=NEW.ID_partita AND (f.anno=c.anno AND f.ID_giocatore=NEW.ID_giocatore)
 INTO s;
  
 UPDATE partita
  SET punti_squadra_1=greatest(0,cast(punti_squadra_1 AS SIGNED)+IF(s=ID_squadra_1,step,0)),
      punti_squadra_2=greatest(0,cast(punti_squadra_2 AS SIGNED)+IF(s=ID_squadra_2,step,0))
  WHERE ID=NEW.ID_partita;
END$
```

Quello che facciamo è prima di tutto calcolare in che squadra gioca chi ha segnato i punti; se i punti sono negativi, si tratta di un autogol, quindi scegliamo l'altra squadra in partita (quella per cui non gioca il giocatore). Alla fine aggiorniamo il punteggio della partita di conseguenza (usando il trucco del singolo UPDATE sui due punteggi con un valore calcolato tramite IF, già usato in altre query). Da notare che usiamo la funzione *greatest* di MySQL per proteggerci da casi "strani" (ad esempio se abbiamo inserito manualmente dei dati errati nella tabella partita) in cui questa operazione potrebbe portare il punteggio al di sotto dello zero. Inoltre, è necessario usare un *cast* per aggiungere il segno a *punti_squadra_1* e *punti_squadra_2* (che sono valori *unsigned*) perchè altrimenti un'espressione come *punti_squadra_1 - 1* potrebbe generare un errore di *data truncation*.

Ovviamente, anche qui dovremmo gestire tutte le possibili modifiche alla tabella segna e aggiornare il campo calcolato di conseguenza:

* Dopo un INSERT si aumenta il punteggio della squadra per cui il giocatore ha segnato

* Dopo un DELETE si decrementa il punteggio della squadra corrispondente al record che viene cancellato

* Dopo un UPDATE si decrementa il punteggio della squadra corrispondente al "vecchio" record e si aumenta il punteggio della squadra corrispondente al "nuovo" record.

Ovviamente anche qui ci conviene modularizzare il codice per evitare ridondanze. Estraiamo quindi dal trigger precedente il codice che calcola la squadra di appartenenza del giocatore *idgiocatore* e somma un numero *step* al punteggio della squadra nella partita *idpartita* per cui sono stati segnati i punti:

```sql
CREATE PROCEDURE step_punti (idpartita integer unsigned,
idgiocatore integer unsigned, step smallint, auto tinyint)
BEGIN
 DECLARE s integer unsigned;
 
 SELECT if(auto<0, 
  if(f.ID_squadra=p.ID_squadra_1,p.ID_squadra_2,p.ID_squadra_1), 
   f.ID_squadra) AS squadra_effettiva
  FROM formazione f 
   JOIN partita p  
   JOIN campionato c ON (c.ID = p.ID_campionato)
  WHERE p.ID=idpartita AND (f.anno=c.anno AND f.ID_giocatore=idgiocatore)
 INTO s;
  
 UPDATE partita
  SET punti_squadra_1=greatest(0,cast(punti_squadra_1 AS SIGNED)+IF(s=ID_squadra_1,step,0)),
      punti_squadra_2=greatest(0,cast(punti_squadra_2 AS SIGNED)+IF(s=ID_squadra_2,step,0))
  WHERE ID=idpartita;
END$  
```

Questa procedura accetta un ulteriore parametro, *auto*, che determina se i punti (*step*) corrispondono a un autogol (se *auto\<0*). Non usiamo a questo scopo
semplicemente il segno di *step* (come facevamo prima con *punti*) perchè vogliamo usare la procedura in modo intelligente, come vedremo qui di seguito. 

A questo punto i tre trigger da realizzare diventano banali:

```sql
CREATE TRIGGER aggiorna_punti_i AFTER INSERT ON segna
FOR EACH ROW BEGIN
 CALL step_punti(NEW.ID_partita,NEW.ID_giocatore,abs(NEW.punti),sign(NEW.punti));
END$
```

```sql
CREATE TRIGGER aggiorna_punti_d AFTER DELETE ON segna
FOR EACH ROW BEGIN
 CALL step_punti(OLD.ID_partita,OLD.ID_giocatore,-abs(OLD.punti),sign(OLD.punti));
END$
```

```sql
CREATE TRIGGER aggiorna_punti_u AFTER UPDATE ON segna
FOR EACH ROW BEGIN
 CALL step_punti(OLD.ID_partita,OLD.ID_giocatore,-abs(OLD.punti),sign(OLD.punti));
 CALL step_punti(NEW.ID_partita,NEW.ID_giocatore,abs(NEW.punti),sign(NEW.punti));
END$
```

Da notare come lo step sia *negativo* nel caso in cui (DELETE e prima parte della UPDATE) si debbano togliere punti invece di aggiungerli. Il valore del parametro *auto* viene invece calcolato con la funzione *sign*, che restituisce -1, 0 o 1 in base al segno del suo argomento.

A questo punto possiamo provare il funzionamento dei trigger inserendo o modificando dei dati nella tabella segna e poi andando a vedere lo stato dalla tabella partita:

```sql
INSERT INTO segna(ID_giocatore, ID_partita, minuto, punti) VALUES (1, 1, 1, 1);
```

```sql
UPDATE segna SET ID_giocatore=3 WHERE ID_giocatore=1 AND ID_partita=1 AND minuto=1;
```

```sql
DELETE FROM segna WHERE ID_giocatore=3 AND ID_partita=1 AND minuto=1;
```

Ovviamente la presenza di un trigger AFTER UPDATE richiede, per essere sicuri che tutto vada bene, che ci sia anche un altro trigger che controlla BEFORE UPDATE la validità del giocatore nel record modificato, come discusso nella sezione precedente.

# Transazioni

In questa sede non possiamo spiegare il concetto di transazione, che è stato ampiamente trattato nella parte teorica del corso di Basi di Dati. Ricordiamo solo che una transazione permette di "raggruppare" più operazioni in un "contenitore" con le proprietà **ACID** (*atomicità* , *consistenza* , *isolamento* , *persistenza*).

Una transazione può essere aperta con lo statement START TRANSACTION. Tuttavia, i DBMS come MySQL aprono automaticamente una transazione, se non è già presente, quando viene loro inviato un comando. Questo vuol dire che, anche se non utilizzate esplicitamente le transazioni, il DBMS le crea comunque "dietro le quinte".

Sappiamo anche che una transazione può essere chiusa e confermata con il comando COMMIT o chiusa e annullata (eliminando gli effetti delle istruzioni in essa contenute) con il comando ROLLBACK. Tuttavia, in MySQL come in molti altri DBMS è attiva per default la cosiddetta **autocommit** : in pratica, il DBMS *esegue una COMMIT implicita dopo ogni istruzione che gli viene inviata*.

In questo modo il DBMS *di default aprirà una transazione per ogni istruzione inviata e la chiuderà, confermandola, subito dopo aver eseguito l'istruzione*. Per usare quindi le transazioni a livello utente, la prima cosa da fare è disabilitare l'autocommit: in MySQL scriveremo

```sql
SET autocommit = 0
```

Ovviamente volendo riattivare l'autocommit basterà usare la stessa istruzione ponendo la variabile a uno anziché a zero.

A questo punto, se inviamo uno statement senza scrivere prima START TRANSACTION, MySQL aprirà comunque una nuova transazione, ma poi la lascerà aperta:

```sql
INSERT INTO campionato(nome,anno) VALUES ("prova",2040);
```

Se dopo aver eseguito questo comando controlliamo la tabella campionato, vedremo che la nuova riga è stata aggiunta. Tuttavia, la transazione non è stata confermata ed è ancora aperta: se inviamo quindi il comando

```sql
ROLLBACK
```

vedremo che gli effetti della transazione (adesso chiusa) sono stati annullati, e il nuovo record è scomparso dalla tabella campionato.

Per chiudere la transazione e confermarne le modifiche apportate al database, avremmo invece dovuto inviare il comando COMMIT.

Alternativamente, è possibile *aprire una transazione esplicita anche mentre l'autocommit è attivo*, usando esplicitamente il comando START TRANSACTION:

```sql
SET autocommit = 1;
START TRANSACTION;
INSERT INTO campionato(nome,anno) VALUES ("prova",2040);
```

Il comando INSERT qui sopra non viene confermato automaticamente, anche se l'autocommit è attivo. Infatti, avendo aperto la transazione in maniera esplicita, 
l'autocommit è stato *sospeso*, e la transazione dovrà essere chiusa esplicitamente:

```sql
COMMIT
```

A questo punto l'autocommit tornerà attivo come da default.

Attenzione: poichè MySQL non supporta *transazioni nidificate*, eseguire una START TRANSACTION quando un'altra transazione è già attiva determina il COMMIT
implicito della transazione corrente e l'apertura successiva di una nuova transazione.