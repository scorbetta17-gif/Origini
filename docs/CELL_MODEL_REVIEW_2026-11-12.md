# Revisione modelli cellulari — 12 novembre 2026

La revisione rende i modelli 3D visibili anche nel gameplay verticale: in precedenza
erano nascosti da sagome 2D. HUD e simboli dei nutrienti restano invariati.
Le forme sono modelli didattici di sviluppo, non ricostruzioni storiche.

## Implementato

- Membrana traslucida blu-verde, RNA viola, DNA a due filamenti con RNA accessorio,
  complessi catalitici ocra e piccoli marcatori del citosol. I sei GLB continuano
  a essere importati e utilizzati; moduli procedurali completano gli asset.
- Movimento del giocatore con filtro smorzato di 75 ms, integrato analiticamente:
  risposta fluida senza lunga inerzia. La locomozione continua a consumare ATP.
- Deformazione comune al corpo e ai suoi moduli; allungamento limitato al 12%
  nella vescicola senza parete, risposta al 22% per involucri paretati. La parte
  affine conserva il volume (determinante 1); le piccole onde locali dello shader
  hanno volume solo approssimativamente conservato. Nessun solutore CFD né vincolo
  fisico esatto sull'area della membrana. Lo scorrimento ottico è simbolico.
- Le strutture ancorate seguono la deformazione; motori batterici e archeali
  ruotano attorno all'asse del filamento. Crescita biologica separata dall'animazione.
- Tutti i 16 loci hanno geometria fenotipica verificabile per livello, tramite
  `feature_nodes`: pori, recettori, pili, secrezione, vescicole, EPS, domini lipidici,
  chaperoni interni, allungamento, pareti/involucri e apparati motori distinti.
- Galleria di otto combinazioni costruite con veri genotipi del gioco. I 48 slot
  dell'albero non sono 48 strutture uniche: alcune vie convergono sugli stessi loci.
- Corretti candidati casuali al cap, livelli persi nella migrazione legacy e
  distinzione fra locus ereditato e struttura espressa nel ramo corrente.
- Eliminati anche i raggi solari residui nel vecchio overlay 2D, ora disattivato.

La scala di presentazione 3D è aumentata uniformemente di 1,45 per mantenere la
cellula leggibile sul telefono. La proporzione di crescita e il formato dei
salvataggi sono conservati. Questa è una convenzione visiva, non una nuova scala
biologica o una modifica al raggio di raccolta.

## Verifica scientifica e mutazioni

[Verifica delle cinque immagini e fonti primarie](CELL_SCIENCE_REVIEW_2026-11-12.md):
vescicola invece di micella; RNA iniziale come scenario ipotetico; DNA e RNA
coesistono dopo la stabilizzazione; LUCA non è la prima cellula e non ha una
forma osservata; nessun nucleo, Golgi o mitocondrio introdotto. Parete, bilayer
lipidico e seconda membrana sono concetti distinti. Colori e dimensioni dei
complessi sono simbolici. Il gate dei motori per ramo è una regola di gameplay.

[Mappatura completa dei loci e delle vie di acquisizione](CELL_MACROMUTATIONS_2026-11-12.md).

## Verifiche e artefatti

- 16 smoke test Godot 4.7.2 superati: inclusi tutti i loci/livelli, eredità e
  divergenza su quattro generazioni, rebuild, migrazione, campagne e fasi 1/2.
- Stabilità con cambi direzione, arresto, velocità estrema, delta negativo e
  input non finito; spostamento equivalente a 30/60/120 FPS; rigidezza della parete.
- 105 controlli statici e sei GLB validati. Il vecchio controllo statico che cercava
  una specifica stringa di implementazione RNA è sostituito dal riferimento ai
  test runtime che verificano gli effettivi modelli RNA/DNA.
- Catture desktop effettive OpenGL Compatibility e Mobile/Vulkan, senza immagini
  modello applicate come screenshot. In `build/previews/`: `cell-rna.png`,
  `cell-dna.png`, `cell-evolved.png`, `cell-gameplay-3d.png`,
  `cell-phenotypes-gallery.png`; prefisso `mobile-` per Vulkan.
- `cell-fluid-motion.gif` contiene 90 frame reali Godot a 30 passi simulati/s;
  camera di revisione e percorso controllato attraverso il codice di locomozione.
  Non misura gli FPS del dispositivo. Generazione facoltativa impostando
  `ORIGIN_CELL_MOTION=1` per `tests/capture_cell_models.gd`.

Le 14 immagini originali (vulcani, fondale, cellule) restano archiviate con SHA-256
in `../modello immagini/`, fuori dal repository. Le prove usano APPDATA isolata.
Prestazioni e leggibilità su telefono fisico restano da misurare; nessuna APK
o release è prodotta. La simulazione non implementa collisioni deformabili,
rottura fisica della membrana o dinamica molecolare.
