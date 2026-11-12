# Cellule: verifica scientifica e specifica artistica

Verifica online del 12 novembre 2026 sui cinque riferimenti forniti dall'utente,
sui 16 loci di `src/cell_genome.gd` e sui vincoli del documento master.
Questo documento motiva le scelte grafiche; non certifica una ricostruzione della
vita primordiale e non prova da solo che ogni proposta sia già implementata.

**Consolidato** indica un fenomeno osservato nei sistemi studiati, non la sua
presenza dimostrata nella prima vita. **Plausibile/in studio** indica scenari
d'origine o ricostruzioni ancestrali. **Astrazione ludica** indica scala, colore,
progressione e meccanica scelti per la leggibilità del gioco.

## Correzioni alle immagini

| Riferimento | Valutazione | Direzione per il modello |
|---|---|---|
| `1-1000049779.jpg`, cellula primordiale | Involucro chiuso e RNA stilizzato sono coerenti con uno scenario protocellulare. Non documentano una cellula storica. | Vescicola lipidica morbida, pochi RNA/ribozimi; niente nucleo, DNA obbligatorio o organelli moderni. I granuli sono simboli di complessi, non organelli. |
| `2-1000049780.jpg`, protocellula a RNA | Non serve una seconda specie identica alla prima: è una formulazione più precisa dello stesso stadio iniziale scelto dal gioco. | RNA a filamento singolo con tratti ripiegati; nessun obbligo di rappresentarlo sempre come una linea perfettamente distesa. |
| `3-1000049776.jpg`, protocellula con DNA | Doppia elica utile come simbolo, ma enormemente ingrandita. Due contorni della stessa membrana non sono automaticamente due membrane. | DNA dopo `dna_stabilization`, RNA accessori ancora presenti; niente involucro nucleare. Una sola membrana lipidica fino a un locus pertinente. |
| `4-1000049777.jpg`, LUCA | La sagoma esatta di LUCA è ignota. La grande linea apparentemente a RNA e le bande interne non vanno copiate come prova di genoma RNA o reticolo endoplasmatico. | Mantenere DNA e RNA, aggiungere complessi non membranosi; nessun Golgi/mitocondrio/nucleo. Aspetto più organizzato, esplicitamente simbolico. |
| `5-1000049775.jpg`, procariote mobile | Forma allungata con appendici è possibile, non universale. Le code illustrate non distinguono i diversi motori. | Eliche rotanti per flagelli/archaella; pili separati, corti e retrattili. Non una coda eucariotica che frusta. |

La ricerca sperimentale usa vescicole di acidi grassi alimentate con micelle:
vescicola e micella non sono sinonimi. Per il compartimento con contenuto acquoso
il termine pertinente è **vescicola protocellulare**, non micella. Crescita e
divisione sperimentali non provano una cronologia universale dell'abiogenesi.
[Zhu e Szostak, 2009](https://doi.org/10.1021/ja900919c).

Non assegnare automaticamente alla prima vescicola la composizione fosfolipidica
moderna. Modelli a lipidi semplici e miscele progressive sono plausibili;
esperimenti mostrano compromessi fra composizione, crescita e permeabilità.
Il pickup «fosfolipide» resta un simbolo di risorsa, non un'analisi chimica della
membrana. [Budin e Szostak, 2011](https://pubmed.ncbi.nlm.nih.gov/21402937/).

RNA catalitico e replicazione incrociata sono stati ottenuti in laboratorio, ma
non equivalgono a una protocellula naturale autosufficiente. La progressione
RNA → DNA è una compressione narrativa dichiarata. LUCA è l'ultimo antenato
comune della vita attuale, non la prima cellula: genoma, habitat e fisiologia
sono ricostruzioni inferenziali. Non ricavare una morfologia certa o un numero
esatto di organelli da tali ricostruzioni.
[Lincoln e Joyce, 2009](https://pubmed.ncbi.nlm.nih.gov/19131595/);
[Moody et al., 2024](https://doi.org/10.1038/s41559-024-02461-1).

## Movimento e membrana

Le vescicole in flusso possono deformarsi e presentare scorrimento tangenziale
della membrana (*tank-treading*) o rotazione globale, in funzione dei parametri.
Il modello fisico include resistenza alla curvatura e vincoli di area; non è una
palla elastica gonfiata che aumenta indefinitamente volume.
[Vlahovska e Serral Gracia, 2007](https://doi.org/10.1103/PhysRevE.75.016313).

A scala microbica le forze viscose dominano: lunghe derive inerziali, turbolenza
macroscopica e rimbalzi persistenti comunicano il regime sbagliato. L'interazione
del joystick e una breve interpolazione visiva rimangono concessioni al gioco.
[Purcell, 1977](https://doi.org/10.1119/1.10903).

Specifica proposta, **astrazione ludica ispirata alla fisica**, non CFD:

- Risposta alla velocità relativa al fluido e rilassamento smorzato. Una
  traslazione uniforme non implica da sola una grande compressione fisica.
- Piccole deformazioni limitate e compensazione del volume; nessuna scala nulla,
  invertita o divergente. La crescita biologica rimane separata dall'ondulazione.
- Movimento tangenziale dei dettagli di superficie, mantenendo fissati alla
  membrana gli attacchi dei moduli e contenuti gli elementi intracellulari.
- Deformazione minore nei modelli con parete; evitare che tutti i procarioti
  assumano la plasticità di una vescicola senza parete.
- Dividere la scissione biologica dall'animazione ordinaria. «Non esplodere» è
  un vincolo numerico/artistico di questa animazione, non l'affermazione che
  membrane reali non possano rompersi o subire lisi.

## Mappatura scientifica dei 16 loci

Tutti i livelli/alleli, conteggi visibili e colori sotto riportati sono simbolici.
Un locus del gioco rappresenta una funzione complessa: non un singolo gene reale
capace di creare istantaneamente un'intera macchina molecolare.

| Locus | Fenotipo leggibile proposto | Limite scientifico e fonte |
|---|---|---|
| `rna_replicase` | RNA singolo ripiegato e piccoli complessi catalitici | RNA catalitico: consolidato; sistema primordiale specifico: ipotesi. [Lincoln/Joyce](https://pubmed.ncbi.nlm.nih.gov/19131595/). |
| `dna_stabilization` | DNA a due filamenti, RNA accessori conservati | Doppia elica ingrandita come simbolo del genoma; non un nucleo. Progressione temporale: astrazione, non ricostruzione esatta. [Moody et al.](https://doi.org/10.1038/s41559-024-02461-1). |
| `membrane_transport` | Canali/complessi inseriti nel bordo, densità distinta per livello | Evitare pori macroscopici aperti in permanenza. I trasportatori hanno struttura e stati conformazionali. [Oldham et al., 2007](https://www.nature.com/articles/nature06264). |
| `surface_recognition` | Piccoli recettori organizzati in gruppi di superficie | Riconoscimento e adesione non sono la stessa funzione; unirli è una semplificazione del locus. [Arrays osservati con crioET](https://pmc.ncbi.nlm.nih.gov/articles/PMC2761316/). |
| `pili_twitch` | Filamenti di contatto retrattili, distinti dalle eliche motrici | La trazione richiede ancoraggio a superficie/oggetto, non equivale al nuoto libero. [Merz et al., 2000](https://pubmed.ncbi.nlm.nih.gov/10993081/). |
| `hydrolase_secretion` | Complessi secretori e piccole particelle enzimatiche esterne | Enzimi, non denti, lame o organelli. Proteine extracellulari/vescicolari osservate non dimostrano una generica «predazione primordiale». [Proteomica sperimentale](https://pubmed.ncbi.nlm.nih.gov/26378716/). |
| `vesicle_pathway` | Piccole gemme/vescicole di superficie | Nessun Golgi automatico; la via rappresenta un insieme semplificato di processi, non una biogenesi universale. [OMV sperimentali](https://pubmed.ncbi.nlm.nih.gov/25198519/). |
| `eps_biosynthesis` | Matrice extracellulare tenue e fibrille esterne | EPS non è una seconda membrana né un guscio rigido. [Architettura di biofilm misurata](https://pmc.ncbi.nlm.nih.gov/articles/PMC3513368/). |
| `thermal_membrane` | Pattern lipidico distinto e risposta meccanica modulata | Falsi colori: non calore luminoso. Nessuna equivalenza universale fra termotolleranza e tetraeteri. [Esperimento su membrane archeali sintetiche](https://doi.org/10.1038/s42003-021-02178-y). |
| `chaperone_complex` | Piccoli complessi proteici ad anello nel citoplasma | Cavità proteica, non organello membranoso; separato da `thermal_membrane`. Forma ispirata a strutture moderne, non prova di origine. [Xu et al., 1997](https://www.nature.com/articles/41944). |
| `cell_elongation` | Rapporto fra assi crescente, contenuti ancora confinati | Organizzazione della forma è multifattoriale; allungamento non coincide con superiorità evolutiva. [Modello meccanico MreB/parete](https://pmc.ncbi.nlm.nih.gov/articles/PMC3136767/). |
| `monoderm_envelope` | Una membrana e parete esterna reticolare | La parete non è una seconda membrana. Spessore e rigidità sono convenzioni visive del modello. [Confronto con involucro diderma](https://www.nature.com/articles/s41467-023-42601-y). |
| `diderm_envelope` | Due membrane con parete interposta e spazio distinguibile | Non confondere i due foglietti di un bilayer con due membrane. Acquisizione lineare monoderma→diderma: scelta di progressione, non storia accertata. [OmpM/peptidoglicano](https://www.nature.com/articles/s41467-023-42601-y). |
| `archaeal_envelope` | Chimica lipidica indicata da pattern e reticolo S-layer | S-layer è uno schema rappresentativo, non una caratteristica identica/universale di tutti gli Archaea. [CrioET di Sulfolobus](https://doi.org/10.1073/pnas.1911262116). |
| `flagellar_motor` | Motore basale ed elica rotante | La rotazione batterica usa gradienti ionici; il costo ATP aggregato nel gioco è un proxy metabolico. [Deme et al., 2020](https://www.nature.com/articles/s41564-020-0788-8). |
| `archaellar_motor` | Elica rotante più sottile, base diversa dal flagello | Macchina distinta ATP-dipendente, non flagello batterico rinominato. [Struttura 2022](https://www.nature.com/articles/s41467-022-28337-1). |

Il vincolo di gameplay «flagello nel ramo Bacteria, archaellum nel ramo Archaea»
è utile alla differenziazione ma non una legge biologica senza eccezioni: uno
studio del 2025 ha dimostrato archaella funzionali nel batterio
*Litorilinea aerophila* e ne analizza il trasferimento orizzontale.
[Studio primario](https://pmc.ncbi.nlm.nih.gov/articles/PMC12488501/).

## Criteri di revisione delle catture

Confrontare origine, DNA, LUCA, batterio paretato e archeo: nessun nucleo prematuro,
RNA non cancellato biologicamente dal DNA, parete distinta da membrana, appendici
legate al genotipo. Verificare che termotolleranza e chaperoni producano dettagli
distinti, che figlie con gli stessi loci ereditino gli stessi moduli e che livelli
diversi restino riconoscibili senza riempire l'interno di organelli inventati.

Trasparenza, tinte ciano/viola/arancio, conteggi ridotti, eliche ingrandite e
sezione ottica dell'interno sono convenzioni illustrative. Le molecole non sono
visibili a occhio nudo in questo modo. Nessuna delle cinque immagini è una
micrografia o una fonte scientifica; nessun loro raggio solare va reintrodotto
nell'ambiente già approvato dall'utente.
