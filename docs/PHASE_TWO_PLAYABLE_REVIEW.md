# Revisione del gioco e Fase 2 giocabile

Revisione del ramo `work/phase-two-playable`, derivato da `work/mutation-balance`. Specifiche: documento master del 12 novembre 2026, con prevalenza delle successive modifiche a cellule, fondale e mutazioni. Le due fasi restano separate; nessuna eucariogenesi aggiunta.

## Stato verificato

| Area | Stato e verifica |
|---|---|
| Movimento, ATP, raccolta e rigenerazione | Implementati; prova di campagna con risorse realmente raccolte |
| Scissione e popolazioni autonome | Implementate; campagna raggiunge gen6 e soglie demografiche |
| Mutazioni e fenotipi | Implementati; regressioni su albero, genoma, ereditarieta e 16 loci |
| Fase 1 | Giocabile fino al censimento di 75 s e sblocco capitolo |
| Fase 2 | Ricerca compatibile, adesione, scambio, stabilita, raccolta, trasmissione e conclusione verificati |
| Genealogia e morte | Causa distinta da scissione; recupero su linea sopravvissuta |
| Salvataggi | Formato71 mantenuto, lettura67/70; checkpoint separato del capitolo |
| Ambiente e modelli | Regressioni esistenti su vulcani, faglie, fondale, membrane, moduli e galleria |
| Mobile | Layout portrait e catture Godot; prestazioni/touch su telefono fisico non verificati in questa revisione |
| Eucarioti, endosimbiosi, multiplayer | Non implementati; oltre lo scopo delle Fasi 1 e 2 |

## Bug corretti

1. Stabilita storica di un precedente partner riutilizzata per un nuovo consorzio: ora richiede i timer del legame attuale, trasportatori ed energia sufficiente.
2. Una quantita minima di carbonio poteva certificare un intero intervallo di scambio: tempo accreditato proporzionale a carbonio ed energia effettivamente disponibili.
3. Particelle di scambio mostrate anche senza risorse: ora seguono il trasferimento reale.
4. Bussola e adesione potevano puntare a Bacteria non capaci di scambio: ricerca di candidati con adesine e trasportatori, oppure partner gia legato.
5. Una Bacteria esterna molto distante impediva nuovi incontri locali: disponibilita locale entro24 unita, intervallo20 s e tetto demografico.
6. Il partner poteva attaccare l'ospite, e il giocatore selezionare accidentalmente il partner come preda: esclusione reciproca durante il legame.
7. Partner fermo incapace di raccogliere nutrienti: raccolta locale mantenuta, piccolo foraggiamento quando esausto e vicino all'ospite.
8. La morte era aggirabile chiudendo il pannello o rigenerando: HP0 resta fatale, niente divisione o nuovo autosalvataggio sul frame fatale; possibile continuare con una linea viva.
9. Salvataggio con posizione della cellula malformata: validazione prima di distruggere la scena. Controlli anche su duplicati, contenitori, valori numerici e cellula controllata.
10. Contatore ID obsoleto nel salvataggio: riallineato a cellule e genealogia per evitare collisioni.
11. Schermata di vittoria ripetuta a ogni successiva scissione: mostrata soltanto alla prima trasmissione.
12. Stabilita non rivalidata immediatamente prima di ereditare: verifica del partner attuale alla scelta della figlia.

## Percorso giocabile

1. Completa la Fase1: sei generazioni, almeno tre divisioni autonome, dieci cellule e censimento75 s. Rigenera e sfuggi ai predatori: non basta restare fermi.
2. Entra nel pannello Fase2. Se controlli Bacteria, segui una linea Archaea; la cellula precedente resta nel mondo. In assenza di Archaea vive e con spazio demografico si incontra una linea indipendente, registrata senza falso antenato.
3. Seleziona recettori/EPS e trasportatori nelle figlie successive oppure tramite l'albero. I requisiti mancanti sono indicati nel pannello.
4. Premi COOPERA o CERCA PARTNER COMPATIBILE. L'avvicinamento usa movimento e ATP normali; il joystick lo interrompe. Nessun teletrasporto del partner.
5. Mantieni distanza entro3,7 unita, accumula12 s di scambio effettivo e25 s di contatto. Oltre8 unita il legame si scioglie; progressi storici rimangono documentati, ma il nuovo legame deve riqualificarsi.
6. Da CONSORZIO/GESTISCI sospendi lo scambio per conservare carbonio. La sospensione non paga nuovi secondi di scambio; la stabilita ottenuta resta valida finche vicinanza, geni ed energia sono adeguati.
7. Raccogli le normali risorse di scissione, dividi e scegli una figlia. Il partner resta una cellula separata; la trasmissione conclude il capitolo. Puoi continuare l'esplorazione.

Separazione volontaria e ripresa sono disponibili nel pannello. Divisione o perdita del partner, caricamento e ritorno a una linea sono gestiti. Il partner puo ancora dividersi autonomamente: il legame segue una discendente.

## Checkpoint e compatibilita

All'apertura della Fase2 viene scritto `user://origini_phase_two.json`, separato dal salvataggio ordinario `origini_067.json` (nome storico, formato71). Il menu offre la ripresa di questo checkpoint. Un vecchio salvataggio gia in Fase2 crea il checkpoint al primo caricamento se assente: in quel caso rappresenta lo stato importato, non un inizio ricostruito. Rigiocare sostituisce la sessione attiva come un caricamento normale; il file ordinario non viene riscritto nel momento della lettura.

## Prove

20 smoke test Godot, 113 controlli statici, validazione dei6 GLB, controllo diff e catture portrait reali. Nuovi test:

- `phase_two_regression_smoke.gd`: scarsita, stabilita obsoleta, pausa, distanza, perdita/divisione partner, recupero ramo, save malformato, morte.
- `phase_two_playthrough_smoke.gd`: fixture iniziale del capitolo, poi mondo attivo, ricerca, alimentazione reale e scissione senza regalare risorse.
- `campaign_playthrough_smoke.gd`: dalla protocellula RNA alla conclusione della Fase2, senza assegnare risorse o punti; usa movimento, raccolta, rigenerazione e divisioni reali. Seed6012: ingresso Fase2 a204,75 s simulati, popolazione18, divisioni autonome15. E una rotta automatizzata, non una durata garantita per una persona.
- `capture_phase_two.gd`: schermate autentiche del pannello e del consorzio. La scena di cattura prepara un genotipo e uno stato di capitolo dichiarati, non una partita dell'utente.

Gli esiti automatici coprono questi scenari; non dimostrano assenza di ogni bug o bilanciamento definitivo. Nessun APK o release prodotto per questo ramo: la prova disponibile e il progetto Godot avviabile con il launcher della workspace. Una prova su smartphone rimane necessaria per prestazioni e comodita dei controlli.
