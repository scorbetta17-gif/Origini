# Alternativa C — capacità cellulare ed energia

Proposta indipendente del 13/11/2026. Non applicata al runtime. Sono stati letti il master 12/11, il dossier 13/11 fornito, `mutation_balance.gd`, `cell_physiology.gd`, `cell_genome.gd` e i test pertinenti. Il modello esistente usa upkeep ATP 0,10/s, movimento 0,18/unità, riserve iniziali 6/4/3/1 e biomassa 23 contro fabbisogni 24/15/12/8 e biomassa 65. Queste differenze impediscono di trasformare direttamente uno score astratto in secondi misurati.

## Regola proposta

Il file `config.json` usa la formula del confronto comune: `clamp(1+gain*(1-exp(-investimento/20))-somma(coeff*(investimento_sorgente/40)^1.3), floor, cap)`. HP usa vitality; mutation è un moltiplicatore dei punti, sempre 1..1,5. Gli investimenti sono punti cumulativi destinati agli assi, non generazioni o percentuali biologiche.

Il costo autonomo della capacità espressa è essenziale: `upkeep = 0,10 + 0,0018*somma(investimenti) + 0,000024*somma(investimenti²)` ATP/s. Evita che una penalità già al floor diventi una discarica gratuita per nuovi vantaggi. Metabolismo migliora la conversione energetica ma non elimina l'upkeep; uptake aumenta il recupero, non genera materia. Per la versione giocabile applicare il costo alla capacità attiva, rendere possibile disattivare moduli e conservare punti non spesi: obbligare a spendere tutto a budget elevato è dannoso.

Divisione completata: 2 punti base, moltiplicati per mutation, con residuo frazionario persistente. Nessuna estrazione casuale di due figlie da scegliere; entrambe ereditano il genoma valido, il controllo resta deterministicamente nella figlia designata. Albero spaziale con nodi minori da 1 punto, strutture maggiori da 6–10 e prerequisiti di funzione/linea; nessun acquisto rende automaticamente espressa una funzione incompatibile. I punti sono una convenzione di agency del giocatore: non significano che la selezione diriga le mutazioni verso un bisogno.

Dominanza di nicchia: densità della linea almeno 30 cellule/km² e almeno 1,5 volte la densità della rivale più numerosa, nella stessa area e finestra. Usare area simulata esplicita, non numero in viewport. Le soglie inclusive sono testate; una finestra temporale anti-oscillazione è consigliata ma non simulata qui.

## Esperimento riproducibile ed esito

Comando dalla cartella game: `python docs/balance_candidates/c/experiment.py`. Python standard library, seed 20261113, output `results.json`. 10.029 build per budget (7 specialiste, 21 coppie, 1 bilanciata, 10.000 casuali), budget 10/30/60/120/240, cinque habitat: ricco, povero, disperso, predatori, prede. Totale 50.145 build e 250.725 valutazioni. PASS limiti di tutti gli assi, mutation 1..1,5, confini di dominanza. Nessun salvataggio aperto o modificato.

Lo score è surplus energetico moltiplicato per sopravvivenza astratta. Le formule e tutti i coefficienti sono nel codice; non è un playtest Godot e non simula inseguimento, geometria, densità emergenti o comportamento NPC. Non prova una dominanza ecologica reale.

| Budget | Risultato osservato | Criticità |
|---|---|---|
| 10 | metabolismo+uptake vince tutti i cinque habitat | Apertura troppo uniforme |
| 30 | stessa coppia vince ricco/povero/disperso, altri ibridi vincono gli altri due | Diversità emerge lentamente |
| 60 | quattro vincitori distinti sui cinque habitat | Costi ancora gestibili, 0–0,04% build senza surplus |
| 120 | quattro vincitori distinti, massimo score ricco 2,0574 | 17,46% build senza surplus in povero; **4 build hanno tutti i sei assi ordinari >1,20** |
| 240 | score massimo ricco scende a 1,5790 | 46,26–87,28% build senza surplus; spendere tutto punisce troppo |

Il controesempio delle quattro build dimostra che i tradeoff da soli non garantiscono matematicamente l'assenza della supercellula. Non raccomando C invariata come scelta finale. È utile come vincolo energetico per una delle altre proposte. Per renderla eleggibile occorre aggiungere una capacità espressa limitata (per esempio massimo tre assi ordinari sopra 1,20 simultaneamente), rendere trasparenti inattivazione e costi, poi ripetere il confronto. Quel limite aggiuntivo NON è incluso nei risultati e non va presentato come verificato. Anche il vincitore universale iniziale richiede validazione del modello di approvvigionamento: può essere un difetto dello score più che del gioco.

## Durata e progressione

Obiettivo progettuale: prima divisione 60–120 secondi con risorse raggiungibili senza motori o predazione. Sequenza di riferimento: 12 divisioni a 90 s, 20 a 120 s, 24 a 150 s, 24 a 180 s: **80 divisioni, 190 minuti attivi**, 160 punti base; massimo teorico 240 punti soltanto se il moltiplicatore fosse 1,5 fin dall'inizio. Con esplorazione, decisioni e fallimenti, obiettivo circa 4–6 ore fino a uno stadio LECA. Sono target, non misure: il test verifica soltanto l'aritmetica. Dossier propone quote 15/25/30/30, qui la divisione del tempo è circa 9/21/32/38 per favorire l'accesso iniziale; questa deviazione è deliberata da confrontare in playtest.

La durata non deve dipendere solo dal prezzo delle statistiche. Nucleo, traffico RE/Golgi, integrazione mitocondriale, citoscheletro e trasmissione stabile restano condizioni indipendenti. La fase 2 resta separata dalla fase 1; LECA è progettazione successiva, non contenuto oggi già verificato. Budget avanzati finanziano innovazioni e capacità alternative, non 240 punti obbligatoriamente attivi negli assi di base. Per i salvataggi: nuovi campi versionati e predefiniti, nessuna reinterpretazione di mutation legacy senza migrazione esplicita.

## Flagelli e adesione

Non imporre un divieto genetico universale fra apparato motore e adesione. Consigliare un costo di **stato espresso**: in ancoraggio stabile il movimento volontario diventa nullo o molto ridotto, il motore spento riduce il costo; in dispersione si recupera la motilità ma si perde il bonus di ritenzione/scambio della colonia. Il passaggio richiede tempo ed energia visibili. Pili/riconoscimento restano distinti dal nuoto; flagello batterico e archaellum mantengono i prerequisiti di ramo già nel genoma. Questi coefficienti sono scelte di gameplay, non stime universali di fisiologia. Nessuna nuova affermazione biologica oltre le distinzioni del dossier è necessaria alla proposta.
