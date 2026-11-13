# Alternative A: conservativa, rendimenti decrescenti

Proposta di bilanciamento GAMEPLAY, non modello biologico validato. Il dossier distingue protocellula narrativa, LUCA ricostruito, analoghi Asgard e integrazione del simbionte; questi coefficienti non attribuiscono probabilita scientifiche alle innovazioni. Le famiglie geniche restano prerequisiti funzionali separati dai modificatori numerici. La scelta intenzionale nell'albero e una convenzione di gioco, non evoluzione teleologica.

## Formula e integrazione

`config.json` contiene la formula esatta, implementata da `phenotype()` in `experiment.py`. Le chiavi di `tradeoffs` sono la statistica che SUBISCE il costo; le sottochiavi sono l'investimento che lo CAUSA. `gains` indica l'ampiezza asintotica: il guadagno marginale iniziale per punto e `gain/20`. Un punto attacco iniziale vale circa +4,15%, non +85%. Il costo cresce con esponente 1,3; raggiungere il tetto non ferma il costo degli ulteriori investimenti. Mostrare il delta completo prima di acquistare.

Conservare investimenti numerici e loci genomici separati nel salvataggio; non riapplicare la formula ai tratti gia trasformati. `mutation` e qui un moltiplicatore crediti con baseline 1 e tetto 1,5, diverso dall'attuale offset legacy baseline zero. Non reinterpretare direttamente i vecchi offset come moltiplicatori. A ogni divisione della linea controllata aggiungere il moltiplicatore a un accumulatore frazionario persistente; spendere solo la parte intera disponibile. Evitare assegnazioni duplicate attraverso le due figlie e farming passivo delle divisioni NPC.

HP massimo = HP base * vitality, mantenendo la frazione HP corrente quando il fenotipo cambia. Attacco, difesa, metabolismo e assorbimento devono essere realmente consumati da combattimento e risorse. La vecchia fisiologia usa gia metabolismo nel costo locomotorio; evitare un secondo bonus energetico globale che moltiplichi assorbimento, metabolismo e riproduzione senza costi. Il vecchio tetto motilita 1,6 e mantenuto. Moduli strutturali rimangono vincolati alla linea genomica.

## Esperimento eseguito

Riproduzione: `python docs/balance_candidates/a/experiment.py` dalla cartella game. Seed 131126; 6.150 build totali: specialisti, tutte le coppie, generalista, controllo senza spesa e 1.200 casuali per budget 10/30/60/120/240. Cinque habitat usano utilita geometriche esplicite in codice. Il risultato completo e `results.json`.

Tutti i test di limiti e accumulo crediti passano. Nessuna build campionata massimizza simultaneamente tutti i cinque habitat. A budget 10 vincono rispettivamente motilita, assorbimento, attacco, difesa, metabolismo; a budget 30 compaiono motilita+assorbimento e difesa+vitalita; a budget 60 quattro habitat favoriscono coppie specializzate. A 120/240 vincono anche build miste casuali. Il risultato registra inoltre la distribuzione della statistica principale nei 25 migliori per habitat.

Limite importante: 739/569/461/307/176 build nei rispettivi budget migliorano tutte le sette statistiche rispetto al principiante. A non impedisce generalisti migliori del principiante; impedisce solo, nel campione e negli habitat assunti, che siano ottimi ovunque. Non e una prova di assenza di super-cellula. La statistica mutazione non conta nell'utilita ecologica e non simula il vantaggio cumulativo su molte generazioni: serve confronto longitudinale in Godot prima dell'accettazione. I punteggi non simulano incontri, morte, risorse finite, frequenze dipendenti dalla popolazione o raggiungimento della dominanza 1,5.

## Durata e nicchie

Raccomandazione esplicita: eta minima riproduttiva 75 s per la linea del giocatore, tempo di riferimento 120 s; 24 divisioni di linea per la fase 1, ulteriori 36 per fase 2, oltre a condizioni funzionali ed ecologiche. Limiti inferiori aritmetici 30/75 minuti (fase 1/intera progressione), riferimenti 48/120 minuti. Non sono durate misurate in partita. NPC richiedono tuning separato per evitare che un rallentamento globale svuoti l'ecosistema.

Nicchia: densita LOCALE della linea >=30 cellule/km2, popolazione della linea >=1,5 volte il rivale locale piu numeroso, mantenute 90 s. Campioni di una sola cellula in aree minuscole non devono qualificare: usare area fissa e conteggio minimo esplicito. Non usare la somma di tutti i rivali al denominatore. Unita km2 e convenzione cartografica ludica, non scala fisica delle cellule. Densita e dominanza sono condizioni separate, non output del presente esperimento. Le stime di ciclo nel JSON sono surrogate `max(75,120/utility)` e non sostituiscono timer misurati.

Preferire A per una migrazione poco invasiva; scegliere un'altra alternativa se il requisito e vietare anche il miglioramento generalizzato rispetto al principiante. Prima di adottarla fare playtest Godot con cinque habitat, risorse consumabili, pressioni ambientali e mutazione cumulativa.
