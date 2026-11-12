# Macromutazioni, ereditarietà e fenotipi — 12 novembre 2026

Il codice contiene **16 loci funzionali**, non 16 singoli geni reali ricostruiti.
Ogni locus rappresenta un insieme di cambiamenti condensato per il gioco. Le
mutazioni minori modificano parametri quantitativi; non creano organelli.
La verifica scientifica e le fonti sono in `CELL_SCIENCE_REVIEW_2026-11-12.md`.

## Mappa dei loci

| Locus | Livello massimo | Acquisizione nel gioco | Segnale fenotipico richiesto |
|---|---:|---|---|
| `rna_replicase` | 1 | Genoma iniziale | RNA a singolo filamento e catalizzatori schematici; nessun nucleo |
| `dna_stabilization` | 1 | Passaggio ludico verso LUCA; linea esterna Bacteria | Doppio filamento DNA distinto dall'RNA; piccoli RNA accessori restano |
| `membrane_transport` | 3 | Albero maggiore o mutazione ereditaria | Complessi di trasporto integrati nella superficie, densità graduata |
| `surface_recognition` | 3 | Albero, mutazione, percorso verso fase 2 | Recettori superficiali corti, distinti dai pili |
| `pili_twitch` | 3 | Albero o mutazione/specializzazione | Pili con attacco alla superficie; lunghezza e densità leggibili |
| `hydrolase_secretion` | 3 | Albero o mutazione/specializzazione | Complessi proteici e secrezione extracellulare, non denti o organelli |
| `vesicle_pathway` | 3 | Albero o mutazione | Piccole gemme/vescicole di secrezione alla membrana |
| `eps_biosynthesis` | 1 | Albero, mutazione, percorso fase 2 | Matrice extracellulare diffusa; non una membrana aggiuntiva |
| `thermal_membrane` | 3 | Albero o mutazione | Pattern lipidico e risposta meccanica della membrana, distinti dai chaperoni |
| `chaperone_complex` | 3 | Albero o mutazione | Complessi proteici interni ad anello, senza membrana propria |
| `cell_elongation` | 2 | Albero o mutazione | Forma progressivamente allungata, distinta dal transitorio di movimento |
| `monoderm_envelope` | 1 | Divergenza Bacteria o mutazione di linea senza involucro | Una membrana e parete; il bilayer non conta come due membrane |
| `diderm_envelope` | 1 | Linea esterna Bacteria nella fase 2 | Due membrane separate con zona interposta; sostituisce l'espressione monoderma |
| `archaeal_envelope` | 1 | Divergenza Archaea | Superficie reticolata e firma lipidica archeale stilizzata, senza nucleo |
| `flagellar_motor` | 2 | Mutazione di linea Bacteria | Apparato flagellare con filamenti elicoidali e punti di inserzione |
| `archaellar_motor` | 2 | Mutazione di linea Archaea | Apparato archaellare distinguibile graficamente; non ciglia eucariotiche |

Il vincolo dei motori ai rami Bacteria/Archaea è una regola del gioco, non un
enunciato universale sulla distribuzione biologica. Dimensioni, colori, numero dei
complessi e ordine degli sblocchi servono alla leggibilità e non sono in scala.

## Albero delle abilità

I 288 nodi sono sei categorie da 48 nodi. Gli otto nodi esterni per categoria
sono 48 **opportunità di acquisizione** dei nove loci comuni, spesso ripetuti.
Non rappresentano 48 differenti strutture o livelli infiniti. Raggiunto il cap,
un ulteriore acquisto del medesimo locus viene rifiutato dal codice UI esistente.

| Categoria | Loci maggiori associati |
|---|---|
| Motilità | Pili, allungamento, recettori, trasporto |
| Attacco | Proteasi, recettori, vescicole |
| Difesa | EPS, lipidi termostabili, chaperoni, allungamento |
| Mutazioni | Recettori, vescicole, trasporto, chaperoni, lipidi termostabili |
| Metabolismo | Trasporto, chaperoni, lipidi termostabili, vescicole |
| Assorbimento | Trasporto, vescicole, recettori, pili |

DNA, involucri e motori seguono invece le tappe di linea e le opportunità
ereditarie sopra indicate. Non si aggiungono nuovi sblocchi o organelli in questa
revisione. La divisione e il passaggio verso LUCA sono compressioni ludiche, non
una cronologia scientificamente dimostrata.

## Difetti riprodotti e corretti

1. I candidati casuali includevano motori già al livello massimo: una mutazione
   maggiore poteva essere selezionata e non cambiare nulla. Ora i candidati
   escludono anche i motori saturi.
2. La migrazione dei vecchi salvataggi senza genoma perdeva trasportatori e
   allungamento e riduceva recettori/motori al primo livello. Ora ricostruisce
   gli interi livelli compatibili dai conteggi legacy, mantenendo la marcatura
   `legacy_inferred` (inferenza tecnica, non ricostruzione biologica).
3. Loci fuori cap potevano produrre quantità eccessive di moduli. La lettura di
   un allele noto è ora limitata a [0, max]; i record originali sono conservati.
4. Vecchi genomi possono contenere entrambi gli involucri batterici. La nuova
   funzione `expressed_allele` distingue informazione ereditata ed espressione:
   il diderma prevale sul monoderma. L'acquisizione di un monoderma già soppresso
   da un diderma non genera un evento fittizio. La storia ancestrale non è rimossa.

## Verifica

`tests/genome_smoke.gd` eseguito con Godot 4.7.2 e dati utente isolati:
origine/minori, eredità sorelle, limiti dei rami, saturazione, conflitto involucri,
migrazione dei moduli, limiti dei conteggi e quattro generazioni con passaggio
JSON. Due linee mantengono combinazioni differenti senza alterare il genitore.
La copertura delle geometrie è verificata separatamente dai test del renderer.

## Galleria collegata al genoma

`CellGallery.tscn` conserva la scena e l'impaginazione a otto cellule, ma ogni
esempio viene ora costruito tramite `CellGenome.grant` e `normalize`. I vecchi
esempi "predatore" e "trasportatori" modificavano principalmente statistiche:
ora la variante secernente possiede davvero proteasi/vescicole e quella EPS
possiede nove complessi di trasporto. Gli otto esempi coprono tutti i 16 loci,
con combinazioni differenti e rami compatibili. Le etichette distinguono RNA,
DNA e LUCA schematico; una nota ricorda che forme e colori sono simbolici.
`tests/gallery_genotype_smoke.gd` verifica combinazioni uniche, copertura completa
e livelli effettivi dei moduli. La galleria non modifica partite o genomi giocati.
