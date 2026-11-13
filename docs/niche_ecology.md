# Nicchie persistenti — contratto di integrazione

`src/niche_ecology.gd` è un modulo puro RefCounted: nessun accesso a scena, salvataggi, RNG o clock. La mappa -1150..1150 su X/Z è suddivisa in 5×5 quadrati di lato 460 unità; assumendo 1000 unità =1 km, ogni area è 0,2116 km². La posizione viene limitata alla griglia ai bordi. Venticinque nicchie hanno cinque habitat distribuiti deterministicamente.

## Autorità e API

- `origin()` restituisce stato vuoto versione1: NON inventa fondatori. Chiamare `register_birth` una sola volta per ogni cellula iniziale reale, oppure per una coorte dichiarata esplicitamente con count intero.
- `normalize(raw)` produce una copia pulita, conserva conteggi positivi e crediti frazionari, ricostruisce habitat canonici. È idempotente; il JSON è interamente serializzabile.
- `register_birth(state,lineage,position,count=1)` e `register_death(...)` mutano e restituiscono state. ID di lignaggio persistente, non ID individuale. `count` è numero reale intero di cellule, mai moltiplicatore visivo. Una fissione 1→2 della stessa linea produce un incremento netto +1; non registrare +2 senza prima sottrarre la madre.
- `differentiate(state,previous,descendant,position,count=1)` trasferisce individui realmente presenti, senza crearne. Le popolazioni residue della linea precedente restano persistenti. Se la differenziazione avviene durante una divisione, contabilizzare separatamente il solo incremento netto +1. Questo metodo non inventa un genoma né decide quando nasce una specie.
- `advance(state,delta,lineage_profiles)` muta e restituisce state, intervalli5s, massimo60s processati per chiamata. Nessun avanzamento offline implicito; il tempo in eccesso viene scartato deliberatamente. Profili `{lineage_id: traits}` oppure `{lineage_id:{traits:traits}}`. Profilo assente = statistiche base1. Nessuna dipendenza da mutazioni casuali.
- `summary(state,lineage,position)` restituisce conteggio proprio, totale, rivale massimo, densità, area, habitat, `dominant`, `coexistence`, status. È sola lettura.

L'aggregato è l'autorità della popolazione. Le entità renderizzate sono rappresentanti di quelle cellule: istanziarne una non aggiunge automaticamente un individuo. Rimozione per streaming/culling non significa morte. Non applicare sia nascite aggregate sia la medesima nascita NPC visibile. Scegliere un solo proprietario demografico per ogni coorte; con questo modulo attivo gli NPC possono visualizzare individui aggregati senza una seconda demografia autonoma. Eventi manuali reali (morte per combattimento, divisione del giocatore) si registrano esattamente una volta. Se una cellula reale migra tra nicchie, sottrarre1 nella vecchia posizione e aggiungere1 nella nuova; spostare la camera o un proxy di rendering non trasferisce popolazioni.

## Crescita e selezione

Nessuna popolazione compare senza fondatori. Ogni habitat ha fitness climatica come media geometrica pesata di statistiche, con pesi espliciti nel sorgente. Predatore favorito in area ricca di prede, raccoglitore su tappeto nutritivo; difesa/HP aiutano fondale esposto, mobilità frammentazione, metabolismo zona povera.

Ogni nicchia possiede risorsa astratta 0..96, inizialmente48; rigenera2,4 ogni5s, paga0,035/cellula/step di mantenimento e1 per nascita. Capacità48 cellule/nicchia. Nascite attese `N*.022*fit*max(0,1-total/48)`. Mortalità attesa `N*(.003 + max(0,1-fit)*.04 + max(0,total/48-1)*.04 + starvation*.08)`. Crediti frazionari persistono fino a diventare eventi interi. Distribuzione proporzionale delle nascite quando risorse/spazio scarseggiano, arrotondata verso il basso senza priorità al nome del lignaggio. I residui delle richieste negate non diventano debiti futuri: evita esplosioni dopo una carestia.

Gli inserimenti espliciti possono superare48: non cancellare individui per soddisfare il cap; la sovrapopolazione aumenta mortalità e blocca crescita spontanea. Non è una simulazione dettagliata di molecole, predazione o risorse3D: collegare quei consumi richiederebbe una sola contabilità condivisa. I profili non includono vantaggi fantasma per mutazione punti. Habitat/capacità restano convenzioni di bilanciamento.

## Soglie

Consolidamento di densità: proprio conteggio /0,2116 >=30 cellule/km² (minimo intero7). Dominanza: densità sufficiente E proprio conteggio >=1,5×il massimo conteggio fra singoli lignaggi rivali. Quindi45 contro30 è il confine esatto;45 contro31 perde dominanza. Non usare la somma dei rivali. Senza rivali resta necessaria densità sufficiente. Coesistenza: densità sufficiente senza dominanza. Il modulo non impone un tempo di stabilizzazione: eventuali missioni devono misurarlo separatamente.

## Verifica eseguita

`tests/niche_ecology_smoke.gd`: PASS su Godot portatile4.7.2 headless, exit0, APPDATA/LOCALAPPDATA isolati in `.tools/niche_ecology_test/`. Verifica25 nicchie, bordi,6/7 cellule alla soglia densità,45/30 e45/31 rivali, perdita di dominio, differenziazione conservativa con persistenza madre, JSON/normalizzazione idempotente, contro-specializzazione su due habitat, assenza di generazione senza fondatori, ripetibilità di120 step, crescita limitata a capacità e morte senza valori negativi. Godot emette l'avviso ambientale di lettura certificati root; il test termina PASS.

Non misura durata di campagna o rappresentazione grafica. Salvare questo stato come nuovo campo opzionale; per vecchi salvataggi inizializzarlo una sola volta dalle cellule salvate effettivamente presenti e memorizzarlo. Non ricostruirlo dai soli NPC visibili ad ogni caricamento, perché ciò perderebbe le coorti fuori schermo.
