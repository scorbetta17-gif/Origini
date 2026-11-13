# Battle Royale ecologico — 0.82

> Documento storico. Per il comportamento corrente, il punteggio su100 e i nuovi percorsi vedere [0.83](BATTLE_ROYALE_083.md).

## Accesso e partita

MENU → Battle Royale → scegli Predazione, Difesa, Mobilità o Cooperazione. Modalità locale per un giocatore contro 12 IA, su un'arena di 80 × 80 unità cartografiche del fondale esistente. La campagna mantiene la sua mappa di 5,29 km². Si parte con una cellula batterica, apparati di digestione e riconoscimento, 6 PM e una specializzazione con bonus e malus. Questa è una modalità competitiva, non una ricostruzione dell'origine dei batteri.

La campagna viene salvata prima dell'ingresso. Partita arena, cronometro, scorte, alleanze, raccolta e tempi di rigenerazione/assorbimento usano `user://battle_royale_082.json`; gli autosalvataggi dell'arena non sovrascrivono la campagna. MENU permette di tornare alla campagna o caricare la partita corrente; il selettore arena permette di riprendere il Battle Royale. Anche il passaggio fra i due salvataggi conserva la partita abbandonata.

La morte della cellula controllata conclude la partita: nessun passaggio a una figlia superstite. La scissione conserva animazione, eredità e PM ma non offre vite aggiuntive. Le figlie sono alleate autonome. I 12 concorrenti iniziali non si replicano, e non compaiono nuovi concorrenti dai gruppi aggregati della campagna.

## Fronti ambientali

Limite di 20 minuti di simulazione attiva, pausa nei menu e durante la scissione. Raggi del rifugio: 34, 28, 22, 16, 10 unità. Nuovo fronte ogni 4 minuti, preavviso di 90 secondi e transizione graduale di 90 secondi; il centro si sposta solo di pochi metri per consentire la migrazione anche ai difensori. Nessun teletrasporto delle cellule.

Il rifugio attuale è verde; quello annunciato è oro. La minimappa mostra giocatore bianco, alleati azzurri, rivali rossi e depositi arancioni. META apre situazione ambientale, distanze e scorte. I fronti alternano acidificazione e calore: fuori dal rifugio peggiorano pH o temperatura e aumenta il danno con la distanza. Difesa e adattamenti di membrana riducono il danno al massimo del 30%; la cooperazione vicina aggiunge il 10%. Non esiste immunità completa. Numeri, fronti e soglie sono astrazioni di gioco.

Le IA anticipano il rifugio annunciato, raccolgono davvero il cibo, si avvicinano ai depositi, evitano predatori o cercano prede secondo il profilo. La rigenerazione NPC usa riserve organiche e lo stesso intervallo di 13,5 secondi del giocatore.

## Risorse contese e strategie

Tre depositi, ciascuno con 60 porzioni condivise per fronte; riposizionamento e nuove scorte al cambio di fronte. Contatto entro 1,9 unità, massimo una porzione ogni 4 secondi per cellula, soltanto se mancano ATP o riserve. Una porzione offre C 4, A 3, L 3, N 2, biomassa 4 e ATP 6, applicando assorbimento e limiti delle riserve. Restano particelle sparse in tutto il rifugio, con distribuzione indipendente dalla posizione del giocatore. Il surplus non diventa risorsa illimitata.

| Specializzazione iniziale | Attacco | Difesa | Mobilità | Assorbimento |
|---|---:|---:|---:|---:|
| Predazione | 1,25 | 0,85 | 0,95 | 0,78 |
| Difesa | 0,78 | 1,35 | 0,82 | 1,00 |
| Mobilità | 0,90 | 0,85 | 1,30 | 1,00 |
| Cooperazione | 0,78 | 1,10 | 0,95 | 1,15 |

COOPERA propone un patto reciproco alla cellula non predatrice libera più vicina entro 5 unità, oppure scioglie il patto. Non richiede l'endosimbiosi archeale della campagna: è un'alleanza ecologica di gioco. Entro 3 unità e con energia sufficiente ciascun partner recupera 0,12 HP/s pagando 0,08 ATP/s e ottiene protezione ambientale. Nessun danno tra alleati finché il patto resta attivo. Due concorrenti cooperativi partono già alleati; il giocatore può stringere un proprio patto. Le alleanze partecipano alla condizione di vittoria condivisa.

Si vince quando non restano rivali esterni alla propria alleanza. A 20 minuti il punteggio confronta vitalità: `0,60 × HP + 0,30 × ATP + min(10, 0,25 × raccolte)`. Vince il giocatore se supera ogni rivale, con pareggio entro 0,01 punti. Nessun punteggio per uccisione; la predazione continua a fornire risorse entro le riserve massime. L'alta mobilità paga i consumi già previsti dalla fisiologia.

## Verifica e limiti

- `tests/battle_royale_smoke.gd`: preavvisi, continuità del fronte, assenza di immunità, 12 concorrenti, scorte e ricarica, alleanza/scioglimento, salvataggi separati, nessuna resurrezione, vittoria e blocco della partita conclusa.
- `tests/battle_playthrough.gd`: dodici simulazioni accelerate, quattro profili sugli stessi tre semi, usando movimento, nutrizione, rigenerazione, combattimento e IA reali. Il pilota automatico non rappresenta l'abilità di una persona e non esplora tutte le combinazioni genetiche. Risultati in `build/battle-playthrough.json`, raccolti anche dalla CI.
- `tests/capture_battle.gd`: catture vere di Godot della selezione, arena con preavviso e pannello META. Il tempo è impostato esplicitamente per verificare l'avviso, non è una partita naturale.
- Suite completa della campagna e controlli statici restano richiesti. Nessun multiplayer, matchmaking o server in questa versione. Il bilanciamento è iniziale e richiede partite umane; prestazioni e leggibilità su un telefono fisico restano da verificare.

I nuovi salvataggi mantengono lo schema 80 con un campo opzionale `battle`: i salvataggi precedenti restano campagne. Si validano i campi arena prima di sostituire lo stato corrente. La build Android 0.82 usa un pacchetto di prova separato; i dati privati delle vecchie APK non si trasferiscono automaticamente.
