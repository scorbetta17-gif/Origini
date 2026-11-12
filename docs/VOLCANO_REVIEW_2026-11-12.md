# ORIGINI — prima revisione vulcani, 12 novembre 2026

Base verificata: `work/remaster-068`, commit
`ba4218a4a8c481259921d73ec9ef760e0bc3fa90`, PR #1 draft.
I job QA e Android del run `43274075502` risultano entrambi riusciti.
Modifiche sviluppate sul ramo separato `work/volcano-reference`.

## Diagnosi del progetto

| Area | Stato osservato |
|---|---|
| Fasi 1/2, scissioni, genealogia e salvataggi | Implementati; 10 test Godot esistenti superati prima delle modifiche |
| Asset cellulari | Sei GLB validi e realmente istanziati; la variante DNA importata mostrava ancora RNA |
| Oceano e termica | Due siti termici e quattro fessure innocue, coordinate coerenti con il gameplay |
| Vulcani precedenti | Coni chiusi: il tappo del CylinderMesh copriva il disco del cratere posto sotto la sommità |
| Nutrienti | Rigenerazione dipendente dai fotogrammi: accumulava ripetutamente `eco_tick + .016` |
| Fenotipo 2.5D | Leggibile ma non rappresenta ancora tutti i loci visualizzati dalla vista 3D; resta da completare |
| Documentazione/versioni | README 0.72, export 0.67 e commenti storici divergono dalla build 0.76: debito preesistente |
| Galleria / vecchi helper | `gallery.gd` usa ancora varianti manuali; `nutrient_glyph_layer.gd` non è referenziato dal gioco corrente |
| Oltre Fase 2 | Visione futura; nessuna eucariogenesi o multicellularità implementata in questa revisione |

Dipendenze: `Main.tscn` → `main.gd` → fisiologia/genoma/fasi, HUD/ritratti,
`cell_visual.gd` → GLB e shader cellulari; `primordial_ocean.gd` → shader
fondale e nuovo `volcano_visual.gd` → shader lava/pennacchio/ombra.
Gli script Blender restano la fonte riproducibile degli asset cellulari.
Le pipeline storiche di ripristino non sono state eseguite.

## Modifiche

- Nuovo costrutto 3D parametrico con basalto sfaccettato, talus, cratere aperto,
  bacino incassato, fratture calde e pennacchio ascendente. Due silhouette con
  semi fissi, mantenendo posizioni, gradiente termico e fessure innocue.
- Ogni vulcano usa 1.350 triangoli per il basalto, una mesh per le fratture,
  una per il bacino, un piano d'ombra e un MultiMesh da 18 particelle.
  Nessuna texture esterna, bloom obbligatorio o simulazione volumetrica.
- Colori vertex sRGB corretti anche per Mobile/Vulkan; shader con colori
  dichiarati esplicitamente. Riferimento tecnico:
  [Godot BaseMaterial3D](https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html#class-basematerial3d-property-vertex-color-is-srgb).
- Generatore casuale dell'ambiente separato da quello del gameplay: cambiare
  la quantità di rocce non consuma più estrazioni destinate a nutrienti/genetica.
  Il terreno è ora riproducibile fra sessioni.
- Nutrienti rigenerati ogni 0,22 secondi di simulazione, con resto temporale
  conservato e tetto di 94; test a 30, 60 e 120 FPS.
- Il locus DNA nasconde l'RNA del GLB e costruisce due filamenti con legami.
  Il ritorno a una linea primordiale ripristina l'RNA e rimuove il DNA.
- Catture generali sincronizzate a `frame_post_draw`, evitando frame vecchi
  subito dopo il cambio di camera o HUD.
- CI del ramo di revisione: QA e screenshot, senza generare un nuovo APK.

## Verifiche locali

- Godot **4.7.2 stable**, hash motore `ed1daf0bf`, Windows.
- NVIDIA GeForce GTX 1050 Ti: rendering reale **OpenGL Compatibility** e
  **Mobile/Vulkan**, non emulazione di telefono.
- **12 smoke test Godot passati**, includendo due nuovi test per crateri/RNG
  e temporizzazione dei nutrienti; test GLB esteso per la transizione RNA/DNA.
- **92 controlli statici** e validazione dei **sei GLB** superati.
- Il controllo geometrico verifica che nessun triangolo roccioso chiuda il
  centro del cratere e che il bacino resti sotto il bordo.
- Catture autentiche in `build/previews/`: `volcano-detail.png`,
  `volcano-reverse.png`, `volcano-gameplay.png` e corrispondenti `mobile-*`.
- Log in `build/audit/`. Nel sandbox Windows compare un avviso di accesso
  al certificate store di sistema, non un errore GDScript o shader.
- Salvataggi di test isolati nella workspace; nessuna partita dell'utente
  sovrascritta. Nessuna modifica al formato v71 o alla firma Android.

La resa è una prima iterazione low-poly: le illustrazioni hanno maggiore
ricchezza di rocce, illuminazione e ambiente. Mancano ancora benchmark e
valutazione della nuova geometria su telefono fisico. Il fondale generale,
le rocce sparse e la UI non sono stati rimodellati in questa iterazione.

## Riferimenti dell'utente

Le quattro fotografie modello originali sono archiviate nella cartella
`modello immagini/` della workspace, esterna al repository `game/`, con indice
e checksum. Sono riferimenti artistici, non frame della build né texture.
Incandescenza e pennacchio sono astrazioni artistiche localizzate; non una
ricostruzione fisica del vulcanismo sottomarino.

Prossimi interventi suggeriti: rocce e sedimenti del fondale, leggibilità
2.5D dei loci mancanti, uniformazione versioni, prova Android fisica.
