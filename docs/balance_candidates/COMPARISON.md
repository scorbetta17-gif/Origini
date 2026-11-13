# Confronto indipendente A/B/C e integrazione

Eseguito `python docs/balance_candidates/compare.py`, seed 20261113: **200.580 build e 1.002.900 valutazioni di habitat**, includendo i tre candidati originali e B con capacità finita. Stesse allocazioni casuali, specialisti e coppie per tutti i candidati, stessi budget 10/30/60/120/240 e stessi cinque habitat del modello energetico C. Risultati completi in `comparison_results.json`. Il comparatore converte esplicitamente A da matrice target→source a source→target; B e C usano già source→target. Il costo energetico di capacità C è applicato identicamente a tutti nel confronto, non trasferito automaticamente al runtime.

| Misura | A | B | C |
|---|---:|---:|---:|
| Vincitori distinti nei cinque habitat, budget 60 | 3 | 3 | 4 |
| Vincitori distinti, budget 240 | 3 | 5 | 3 |
| Build con tutti i sei assi ordinari >1,20, budget 120 | 65 | 41 | 4 |
| Stessa misura, budget 240 | 73 | 2 | 0 |
| Vincitori distinti, budget 10 | 1 | 1 | 1 |

**Scelta operativa: B con capacità finita**, per differenziazione delle build avanzate e maggiore escursione utile delle specializzazioni; non è una prova statistica di superiorità globale. C limita meglio gli aumenti simultanei ma punisce fortemente gli investimenti elevati nel suo modello energetico. A conserva più aumenti simultanei nelle build avanzate. Le diverse conclusioni dei tre esperimenti originali derivano anche da modelli di habitat differenti: soltanto questa prova accoppia campioni e funzione di punteggio.

**Correzione motivata dai controesempi:** nessuno dei candidati originali garantisce l'assenza di sei bonus simultanei oltre +20%. B integrata limita a **1,20 la somma degli incrementi positivi dei sei assi ordinari**, calcolati rispetto alla baseline ereditata; se necessario li riduce proporzionalmente. I malus rimangono, mutation è esclusa. Pertanto da baseline unitaria non possono esistere sei bonus tutti oltre +20%. Il controllo aggiuntivo B_capacity trova zero controesempi in ciascuno dei cinque budget e quattro vincitori distinti a budget 240. I salvataggi precedenti sono esentati solo per il valore ereditato: il limite riguarda le nuove migliorie. È una garanzia circoscritta a questa misura, non una prova di impossibilità di invincibilità nel gioco. Nessun coefficiente è una misura biologica. Sono test analitici, non prove della reale competizione nel mondo Godot o della durata della campagna.

## API integrata in MutationBalance

- `tree_effect(traits, stat, major)` ricalcola da investimenti cumulativi, minor=1 e major=5. Memorizza `balance_version`, `balance_baseline`, `balance_investments`. A parità di investimenti e baseline il risultato è indipendente dall'ordine; ogni ramo ha penalità crescenti. Alla saturazione dei floor alcune ulteriori penalità non sono visibili: evitare di promettere un costo marginale senza limite.
- `normalize` conserva i valori validi legacy anche quando un cap B scende, tramite i precedenti massimi; non altera genoma, strutture o campi sconosciuti. Il primo acquisto fotografa la baseline ereditata. Vecchi valori superiori ai nuovi caps sono mantenuti ma non ulteriormente potenziati. `shift` resta disponibile e aggiorna la baseline se presente.
- `vitality` è un asse opzionale per HP massimi, baseline 1. Il collegamento ai danni/HP appartiene al chiamante.
- `mutation` resta un offset legacy, baseline **0**, cap nuovo 0,50. `points_multiplier(traits)` restituisce `clamp(1+mutation,1,1.5)`; valori legacy negativi non riducono i punti sotto il base. Questa scelta conserva la rappresentazione storica, non introduce un valore base 1 nel campo legacy.
- `division_credit(traits, remainder=0)` restituisce `{points, remainder}`. Il chiamante accredita solo una divisione completata della linea controllata e salva il residuo. Premio base 2, massimo 3; il residuo evita arrotondamenti prematuri.

Le costanti pubbliche e le API precedenti restano disponibili per i chiamanti esistenti; MINOR_GAIN/MAJOR_GAIN sono compatibilità, non la nuova formula. L'albero è aggiornato a 336 nodi: i 288 ID originali mantengono il loro significato; vitalità occupa 288..335. Le anteprime mostrano gli effettivi delta di tutti gli assi, incluso l'effetto della capacità finita, senza un malus fisso inventato. Adattabilità (PM) esplicita la convenzione di gameplay. La fisiologia deve consumare i limiti selezionati coerentemente: questa patch non modifica main o physiology.

## Verifica runtime

`tests/unified_balance_smoke.gd` eseguito con Godot 4.7.2 headless: **PASS**, exit 0. APPDATA e LOCALAPPDATA isolate sotto `.tools/balance-c-test/`; nessun salvataggio utente usato. Verifica ordine inverso degli acquisti, penalità reali, nessuna mutazione dell'input, conservazione dei valori legacy e strutture, roundtrip JSON, 1.000 acquisti e limiti, moltiplicatore estremo, accredito e residuo frazionario su dieci divisioni. Inoltre verifica 300 sequenze casuali a budget 10/30/60/120/240/1000 contro il budget positivo, il nuovo ramo vitalità, il precedente ID enzimi 88, i confini 335/336 e le anteprime con malus. Godot segnala inoltre impossibilità di leggere il root certificate store: non impedisce il test locale.

Il precedente mutation_balance_smoke contiene l'assertion rigida motility<=1,60/metabolism>=0,65 dopo mille acquisti nello stesso ramo. B prevede 1,65 e 0,55: quel controllo descrive il vecchio tuning e va adattato, senza scambiare il cambiamento intenzionale per regressione. Il nuovo test verifica i nuovi limiti espliciti; non sostituisce il playtest completo di alimentazione, divisioni, UI e salvataggi.

## Collegamento fisiologico verificato

`CellPhysiology` usa i caps/floor B per motilità e metabolismo (il massimo metabolico legacy 1,80 resta riconosciuto). Le capacità funzionali vere in `traits.evolution_capabilities` comportano 0,005 ATP/s ciascuna fino a 0,06 ATP/s; nomi di linea, flag false e chiavi sconosciute non costano. L'origine senza moduli mantiene l'upkeep precedente. Il mitocondrio funzionale espone `energy_yield_multiplier=1,15`; un mero simbionte interno o consorzio non riceve il bonus. È una resa energetica di gioco, non materia aggiuntiva né una misura biologica.

`player_speed(traits, anchored=false)`, `npc_speed` e `strategy_speed` accettano uno stato di associazione esplicito: quando attivo, velocità ×0,55. Il genoma e i flagelli restano invariati. `npc_energy_step` accetta opzionalmente i tratti per il costo di complessità. Il main deve passare questi stati/chiamare la resa al recupero energetico; l'API non rende retroattivamente veri i collegamenti del chiamante.

HP rimane normalizzato 0–100 nell'interfaccia; vitalità divide il danno e rappresenta quindi **salute effettiva**, non un nuovo valore massimo mostrato sulla barra. Evitare di promettere una barra da 170 HP.

`unified_physiology_smoke.gd`: PASS Godot headless con dati isolati, limiti e movimento non gratuito, associazione senza modifica dei geni, costi per capacità vere, bonus riservato all'organello funzionale, differenza di consumo esatta 0,6 ATP su 10 s al massimo, morte da ATP. `qa_static.py` aggiorna le verifiche obsolete (organelli sempre assenti, vecchia versione salvataggi, carte figlie) controllando capacità esplicite, eredità deterministica, migrazione 67/70/71/80 e tre esiti distinti della rimozione; conserva verifiche di riferimenti agli asset e aggiunge assenza di TIME nel fondale, faglie e assenza di generatori nominati di raggi. Il controllo statico non sostituisce il rendering.

## Ritmo e significato

Le stime originali restano ipotesi: A e B propongono campagne più lunghe di C; il campione non misura secondi di gioco. Prima divisione accessibile e traguardi tardivi devono essere verificati con risorse raccolte realmente, senza fixture che finanzino la divisione. I controller delle fasi 1 e 2 rimangono distinti per compatibilità, entro la nuova campagna continua; LECA richiede percorsi funzionali aggiuntivi, non solamente punti. Il premio evolutivo è agency di gioco: selezione e disponibilità di risorse non dirigono biologicamente la mutazione verso un risultato voluto.
