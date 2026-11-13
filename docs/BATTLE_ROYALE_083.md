# Arena 0.83 · regole e verifica

Base compatibile: a23ae8a dopo d63e14a. La campagna e l’arena restano separate; la revisione sostituisce la formula 0.82. Modalità locale contro 12 IA, non multiplayer.

## Punteggio su 100

- Vitalità: HP/100 ×25 + ATP/100 ×15; capacità ATP arena 100 sia per il giocatore sia per NPC.
- Nutrizione: min(20, quantità effettiva/150 ×20). Una unità è una unità entrata in carbonio, amminoacidi, lipidi o nucleotidi, qualunque sia la fonte. Biomassa, ATP e surplus non contano. Soglia salvata/configurabile `nutrition_target`; default `battle_scoring.DEFAULT_NUTRITION_TARGET`.
- Eliminazioni: 4 ciascuna, massimo20. Somma dei danni effettivi negli ultimi30 secondi prima della morte; vince il maggiore contributore, parità esatta per ID lessicografico. Nessun credito senza danni di combattimento recenti; registrazione definitiva anche delle morti ambientali, per evitare assegnazioni ripetute. Nessun potenziamento statistico per eliminazione.
- Fronti: 5 punti per ciascuno dei quattro cambi, massimo20. Una sola fra: presenza nel prossimo rifugio con margine2 almeno15 secondi prima; nutrizione effettiva da deposito nei primi45 secondi; passaggio nel rifugio di due alleati entro5 secondi e3 unità durante la transizione. Trovarsi già nel rifugio annunciato vale come anticipo: non si richiede di uscire e rientrare.

Classifica tra superstiti, alleanza valutata sul migliore membro senza somma. Pareggio entro0,0001. Vittoria immediata se nessun rivale rimane; vittoria condivisa con la propria alleanza. La morte del controllato conclude la sua partita come nella0.82, mostrando comunque il riepilogo personale; se ci sono più gruppi ancora vivi, la classifica in quel momento è provvisoria e non una vittoria globale simulata. Non si passa a una figlia dopo la morte. Alla scissione, solo la figlia controllata eredita i contatori già acquisiti; l’altra non ne riceve una copia.

## Percorsi e IA

Preavviso90s: rifugio oro, pericolo esterno ombreggiato, futuri depositi R/S/C e due itinerari sulla minimappa, anelli sul terreno. R è al85% del raggio: porzione12 unità, esposto alla periferia e alla competizione; S al28%:5,4 unità, margine maggiore dal pericolo; C al48%:8,4 unità. Quantità prima di uptake e cap. Ogni deposito conserva60 porzioni condivise e cooldown4s.

Predazione punta a R; Mobilità anticipa S; Difesa sceglie R se sana e con ATP sufficiente, altrimenti S; Cooperazione punta a C e segue il membro con ID minore per evitare un inseguimento reciproco senza direzione. Emergenze energetiche, uscita dal pericolo e minacce vicine possono prevalere. Stessi segnali, risorse e opportunità per giocatore e IA.

## Persistenza e compatibilità

`scores`, `damage`, `credited`, `crossings`, `nutrition_target` nel campo `battle` dello schema80; rimane `user://battle_royale_082.json` per caricare salvataggi esistenti. Le arene0.82 non hanno cronologia del surplus: i nuovi contatori partono da zero al caricamento, senza inventare dati. La campagna continua a usare il proprio percorso separato.

## Simulazioni riproducibili

12 prove con il driver esistente: semi8200–8202, profili0–3, 2400 passi di0,5s. Nessuna risorsa concessa al bot durante la partita. Rapporto integrale: [083-battle-playthrough.json](reports/083-battle-playthrough.json). Baseline storica: [082-battle-baseline.json](reports/082-battle-baseline.json).

La calibrazione iniziale a400 produceva intake dei rappresentanti superstiti min52,08, mediana52,08, massimo188,98: gran parte delle riserve satura e poi viene riutilizzata soltanto con riparazioni e capacità.400 rendeva il contributo medio circa2,6/20. A150, una prima riserva piena vale circa6,9/20, mentre una strategia capace di assorbire ancora può arrivare a20. Il rerun a150 conserva esattamente HP, ATP e intake personali della prova a400: la soglia cambia il risultato, non gli eventi di combattimento.

| Seme | Profilo bot | Esito giocatore | Migliore superstite | V /40 | N /20 | K /20 | F /20 | Totale | Migliore formula0.82 |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| 8200 | Predazione | vittoria | C-000 | 33.91 | 7.83 | 12 | 20 | 73.74 | BR-006 |
| 8200 | Difesa | sconfitta | BR-009 | 32.44 | 10.99 | 16 | 20 | 79.43 | BR-003 |
| 8200 | Mobilità | sconfitta | BR-009 | 33.85 | 10.99 | 20 | 20 | 84.84 | C-000 |
| 8200 | Cooperazione | sconfitta | BR-001 | 35.86 | 8.71 | 16 | 10 | 70.57 | BR-007 |
| 8201 | Predazione | vittoria | C-000 | 32.76 | 7.83 | 12 | 20 | 72.59 | BR-006 |
| 8201 | Difesa | sconfitta | BR-009 | 34.23 | 9.50 | 8 | 20 | 71.72 | BR-011 |
| 8201 | Mobilità | sconfitta | BR-009 | 35.74 | 9.50 | 16 | 20 | 81.24 | BR-007 |
| 8201 | Cooperazione | vittoria | C-000 | 39.36 | 20.00 | 0 | 20 | 79.36 | BR-006 |
| 8202 | Predazione | vittoria | C-000 | 37.81 | 8.71 | 16 | 20 | 82.52 | BR-004 |
| 8202 | Difesa | sconfitta | BR-009 | 33.10 | 9.50 | 12 | 20 | 74.60 | BR-011 |
| 8202 | Mobilità | sconfitta | BR-005 | 29.37 | 8.62 | 12 | 20 | 69.99 | C-000 |
| 8202 | Cooperazione | sconfitta | BR-005 | 28.76 | 13.74 | 16 | 20 | 78.50 | BR-003 |

11/12 arrivano a1200s; una finisce prima per morte del giocatore. Il confronto vecchia/nuova formula usa HP, ATP e contatori legacy degli **stessi eventi nuovi**, applicando per entrambe la selezione del miglior membro dell’alleanza. Non è la riproduzione completa dell’IA o del vecchio risolutore0.82. La riga con eliminazione anticipata è una classifica provvisoria.

- Caso naturale senza eliminazioni: seme8201, Cooperazione, C-000: vitalità39,36 + nutrizione20 + eliminazioni0 + fronti20 =79,36, vittoria.
- Caso naturale in cui le eliminazioni cambiano il vincitore: seme8200, Predazione. C-000 ottiene73,74 con12 punti di eliminazioni; togliendoli scende61,74, sotto il migliore rivale (66,89 circa). Con la formula0.82 vince BR-006.
- Fixture mirate aggiuntive in `battle_scoring_smoke.gd`: riserve piene, unità particella/deposito uguali, più attaccanti, parità, danni scaduti, ambiente, tutti i tre obiettivi, salvataggio/caricamento, alleanza col migliore membro diverso dal controllato.

Il campione è piccolo: la predazione resta favorita (3/3 vittorie del bot predatore contro1/3 cooperativo e0/3 per altri profili). Non si dichiara un equilibrio competitivo definitivo. Gli obiettivi di anticipo sono spesso completati da molti superstiti; il playtest umano dovrà misurare se il preavviso cambia davvero il percorso.

## Verifica e build

31/31 test Godot completi; test mirato dei tre obiettivi rieseguito dopo l’aggiunta dei casi deposito/alleato.160 controlli statici,6 asset Blender validati. Screenshot reali OpenGL con `capture_first_mutation_083.gd`: prima mutazione, scelta al fronte e riepilogo. Sono scene di prova preparate, non fotografie di un playtest umano.

Il driver crea ricorsivamente `build/` prima del report e controlla apertura/scrittura; la CI parte da checkout pulito e conserva `build/battle-playthrough.json`. APK0.83 costruito dal workflow del repository, package debug separato `org.origini.mobile.unified083`. Installazione e prestazioni su telefono fisico e [playtest umano](PLAYTEST_083.md) restano da eseguire.
