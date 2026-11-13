# ORIGINI 0.80 — campagna continua

La richiesta del 13 novembre 2026 sostituisce le missioni separate Fase 1/Fase 2. La simulazione parte dalla Cellula Zero, consente specializzazioni e linee alternative, e arriva a un eucariote unicellulare di grado LECA. Non include animali o vita terrestre.

## Scissione e scelta

La scissione dura 2,4 secondi: duplicazione del materiale genetico, allungamento e strozzatura della membrana, due figlie vive. Si continua automaticamente con la prima; l'altra rimane autonoma. La genealogia permette di cambiare linea. Nessuna scelta casuale di varianti alla divisione del giocatore.

Ogni divisione attribuisce 2 PM, fino a 3 con adattabilità. Il saldo è frazionario e persistente. PM e scelte dirette sono un'astrazione di agency: la pressione selettiva biologica non orienta intenzionalmente le mutazioni. I genomi sono ereditati; gli NPC mantengono diversificazione autonoma.

L'albero delle specializzazioni ha 336 nodi: 280 puntiformi e 56 maggiori, in sette rami (mobilità, attacco, difesa, adattabilità, metabolismo, assorbimento, vitalità). Gli ID dei precedenti 288 nodi sono conservati. Un locus già al massimo non impedisce di attraversare il cluster: acquisti una specializzazione quantitativa senza creare alleli aggiuntivi. Vitalità aumenta la salute effettiva riducendo il danno; la barra resta percentuale 0–100. La divisione non causa più una lesione automatica del 15%.

## Progressione funzionale

Il pannello Capacità condivide i PM con l'albero e presenta 23 nodi con prerequisiti, costo, divisioni richieste e grado di certezza della descrizione. DNA, LUCA e scelta Bacteria/Archaea non sono più varianti automatiche offerte dalla scissione.

Il ramo archeale conduce a ospite affine agli Asgard e citoscheletro; traffico di membrane/nucleo/RE-Golgi possono maturare in parallelo alla simbiosi. Il consorzio richiede scambio con un partner batterico reale per più divisioni. L'internalizzazione trasferisce quel donatore dall'ambiente all'ospite conservandone ID e linea; non lo trasforma in detriti e non lo rende subito mitocondrio. Import proteico, integrazione metabolica e divisione coordinata sono acquisizioni separate. Il mitocondrio funzionale dà una resa energetica limitata a +15%; il semplice simbionte interno non la dà. LECA richiede almeno 60 divisioni e otto trasmissioni integrate dopo i prerequisiti.

Il costo di complessità è al massimo 0,06 ATP/s aggiuntivi. L'associazione esterna riduce la mobilità al 55% senza cancellare flagelli o altri geni. L'ordine selezionabile è uno scenario ludico, non una cronologia risolta dell'eucariogenesi. I singoli moduli sono binari acquisito/non acquisito; i contatori di stabilità descrivono la maturazione, non ancora un modello completo assente/incipiente/funzionale/specializzato. L'ereditarietà interna è deterministica in questa versione; perdita stocastica e riduzione genomica dettagliata non sono simulate.

## Nicchie e popolazioni

La mappa cartografica di 2300×2300 unità equivale a 5,29 km², suddivisi in 25 nicchie da 0,2116 km². È una scala simbolica: la cellula visualizzata non misura metri. Soglia 30 cellule/km² (quindi almeno 7 individui per nicchia), dominanza se la linea raggiunge 1,5 volte il rivale più numeroso; altrimenti coesistenza sopra soglia.

Le cellule vicine hanno nutrizione e demografia individuali. Quelle oltre 42 unità dal giocatore passano a coorti intere persistenti, con risorse aggregate, capacità portante 48 e fitness dipendente dall'habitat. Il censimento include ciascuna cellula una volta; gli individui attivi vengono esclusi dall'avanzamento demografico aggregato. Tornando in una nicchia si materializzano rappresentanti senza creare nascite. Le risorse delle coorti sono un modello ecologico astratto distinto dalle molecole 3D.

Gli acquisti differenziano la cellula controllata in una nuova linea ecologica. Le popolazioni precedenti restano. I movimenti individuali trasferiscono il conteggio fra nicchie; esplorazione, divisioni e popolazioni lasciate sul posto fondano nuovi insediamenti. La genealogia delle coorti non è ricostruita per ogni nascita aggregata.

## Bilanciamento e ritmo

Tre agenti hanno prodotto A/B/C, ciascuna con esperimento riproducibile. Il confronto comune include 200.580 build e 1.002.900 valutazioni di habitat. È stata scelta B con una capacità finita: somma dei nuovi incrementi positivi dei sei assi ordinari ≤1,20, con malus conservati e rendimenti decrescenti. Il test non prova assenza di strategie dominanti nella simulazione reale. Baseline legacy preservata. Vedere [confronto e controesempi](balance_candidates/COMPARISON.md).

Prima divisione non prima di 35 s; successive non prima di 75 s, oltre a nutrienti e ATP. LECA ha quindi un minimo teorico di 74 min 20 s di simulazione, più animazioni, scambi ed esplorazione. Non è una durata media misurata. La raccolta ottimizzata nei primi tre cicli può completarsi prima del timer: la maturazione resta un limite di ritmo da rivedere con playtest, non attività aggiuntiva simulata.

## Migrazione e prove

Salvataggio schema 80; caricamento 67/70/71 conservato. Migrazione delle capacità dedotta soltanto dal ramo già presente: nessuna endosimbiosi inventata a partire da un consorzio esterno. Wallet frazionario, ID, donor provenance, nicchie, crediti demografici e progresso sopravvivono a due roundtrip. I moduli delle vecchie fasi restano come compatibilità e gestione dello scambio, non come campagne separate.

Verifica locale consolidata: **26/26 smoke test Godot**, **131 controlli statici**, catture autentiche OpenGL e Mobile/Vulkan. Il test fino a LECA è accelerato con risorse e maturità predisposte. Un test distinto foraggia realmente e ottiene tre divisioni a 35,00 / 110,04 / 185,08 secondi simulati, senza assegnare risorse o ATP. Nessun test misura ancora una campagna intera naturale o le prestazioni su telefono fisico.

I tre vecchi test che assumevano la selezione di varianti e la successione obbligata di due fasi sono archiviati in `tests/legacy/`; i test attivi verificano la nuova campagna e la migrazione. Esecuzione: `python tests/run_suite.py --timeout 180`.

Documenti utente letti integralmente e archiviati in `../modello immagini/ricerca-eucariogenesi/`: dossier Markdown e diagramma PDF. Le categorie CONSENSUS/PLAUSIBLE/CONTROVERSIAL/GAMEPLAY seguono quel dossier; non costituiscono una revisione indipendente di ogni pubblicazione citata.
