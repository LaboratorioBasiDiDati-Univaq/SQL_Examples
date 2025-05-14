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
