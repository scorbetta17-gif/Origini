# Revisione cellule, scissione e statistiche — 0.81

## Comportamento

- La scissione è pronta al 100% solo con nutrienti, ATP e maturità del ciclo sufficienti. La barra prima ignorava la maturità: poteva mostrare 100% e rifiutare la divisione.
- Nutrienti mancanti: «Raccogli tutti i nutrienti necessari». ATP o maturità mancanti hanno un messaggio specifico. Avviso in basso, durata 3,5 secondi di orologio reale, anche durante un menu in pausa.
- Membrana ovoidale regolare con deformazione direzionale limitata; crescita invariata, massimo +20% lineare.
- DNA: un filamento continuo viola avvolto in un piccolo volume tridimensionale, simbolo di materiale genetico condensato. RNA arancione distinto, presente anche nelle cellule DNA.
- Flagello batterico: piccola inserzione, hook e lungo filamento elicoidale sottile. Ruota soltanto il filamento. Archaellum distinto con raccordo generico; proporzioni e velocità artistiche, non simulazione molecolare. [Ricerca dell'agente e fonti primarie](FLAGELLA_RESEARCH_081.md).

## Statistiche

MENU → Statistiche e popolazioni, oppure META → Statistiche. Selettore nicchia attuale/intera mappa, filtro RNA/DNA, dettagli espandibili per linea con densità, genoma, mobilità, attacco e difesa.

Occupazione: cellule / capacità convenzionale, 48 per nicchia. Composizione: cellule di un gruppo / tutte le cellule presenti. Due RNA su 48 occupano il 4,17% della capacità ma costituiscono il 100% della popolazione. Non sono superfici fisiche delle cellule. Le regole preesistenti di dominanza e coesistenza non cambiano. Il censimento legge anche i gruppi aggregati fuori schermo senza aggiungere le rappresentazioni grafiche una seconda volta.

Contatori persistenti: divisioni completate, particelle raccolte, porzioni digerite, prede eliminate e quantità effettivamente entrate nelle riserve per nutriente. Il surplus scartato non conta. I vecchi salvataggi restano leggibili, ma non permettono di ricostruire raccolte passate: il pannello segnala da quando iniziano i nuovi conteggi.

## Verifiche riproducibili

`python tests/run_suite.py --timeout 180` comprende i nuovi `statistics_feedback_smoke.gd` e `cell_redesign_smoke.gd`: denominatori del censimento, lettura senza mutazioni, filtri, avviso in pausa, cause della mancata divisione, assorbimento con riserve piene, divisione contata una sola volta, salvataggi, DNA tridimensionale viola e ancoraggio del flagello durante la rotazione.

Rendering reale Godot Compatibility/OpenGL: `tests/capture_cell_models.gd` e `tests/capture_statistics.gd`. Quest'ultimo usa esplicitamente una popolazione di prova di 2 RNA e 6 DNA; non è una partita naturale. Immagini in `build/previews/081-*.png`. Non sono immagini generate. Prestazioni e resa su telefono fisico restano da verificare.

## Idee battle royale — proposte, non implementate

1. **Sopravvive la linea**: si perde quando non restano discendenti vivi; morire nella cellula controllata permette di passare a una figlia superstite. Il limite di vite evita di rendere irrilevante la sopravvivenza.
2. **Nicchie che diventano inospitali**: fronti di temperatura, pH o esaurimento delle risorse annunciati in anticipo spingono le linee a migrare verso rifugi mobili. Non attribuire questo restringimento alla storia evolutiva reale: è una modalità di gioco.
3. **Vittoria non solo per predazione**: si può resistere attraverso difesa, foraggiamento, mobilità o cooperazione. Ultima linea vitale, oppure miglior punteggio ecologico a tempo limite, evitando stalli fra difensori.
4. **Cibo abbondante ma conteso**: depositi concentrati danno risorse per più divisioni, attirando concorrenti; zone periferiche più sicure alimentano lentamente. I premi delle uccisioni restano limitati per frenare il vantaggio cumulativo.
5. **Modalità separata dalla campagna**: partire con partite da circa 20–30 minuti contro IA, obiettivo da verificare nei playtest. Una linea locale RNA/DNA è una categoria biologica, non necessariamente una squadra: il sistema deve distinguere gruppi biologici e discendenza del giocatore.

Primo prototipo consigliato: sopravvivenza della linea, tre fronti ambientali leggibili, rifugi e confronto finale di vitalità. Multiplayer, matchmaking e riduzione della mappa non fanno parte di questa revisione.
