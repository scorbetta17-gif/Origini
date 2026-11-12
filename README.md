# ORIGINI — Gioco Android 0.70 · Fase 1 + Fase 2

**Stato:** versione giocabile completa fino al traguardo della Fase 2, sviluppata in **Godot 4.7.2**, con modelli cellulari originali generati da **Blender** ed esportati in **glTF/GLB**.

Il progetto parte da una **cellula primordiale** composta da membrana, singolo RNA e tre complessi autocatalitici. Il giocatore nutre la cellula, accumula biomassa e ATP, si divide in **due figlie vive**, sceglie quale controllare e segue la genealogia delle altre popolazioni. Le mutazioni minori modificano le statistiche; quelle maggiori cambiano loci ereditabili e introducono strutture 3D coerenti.

## Contenuti giocabili
### Fase 1 — Origine e diversificazione
- Cellula iniziale essenziale in oceano primordiale senza vita macroscopica.
- Raccolta di carbonio, amminoacidi, lipidi e materiale nucleico; biomassa e ATP.
- Scissione in due discendenti, antenati genealogici, NPC indipendenti e selezione della linea.
- DNA stabile come traguardo semplificato, poi divergenza in Bacteria e Archaea da antenati comuni.
- Genoma modulare, albero con bonus passivi, fenotipi visibili (pili, recettori, EPS, trasportatori, proteasi, vescicole, termotolleranza).
- Predazione, proteolisi, rigenerazione, ambienti termici con sorgenti idrotermali e danni.

### Fase 2 — Cooperazione procariotica
Traguardi in cinque tappe:
1. Riconosci una cellula **Bacteria** separata dalla linea Archaea.
2. Forma un'adesione recettore/EPS-dipendente.
3. Scambia metaboliti per almeno **12 secondi** reali (consuma carbonio, modifica ATP ed energia del partner).
4. Mantieni il consorzio metabolico per **25 secondi** di vicinanza stabile.
5. Completa una scissione e segui la figlia che eredita i loci e l'associazione cooperativa.

**Traguardo di fine Fase 2:** consorzio metabolico stabile e trasmissibile.
Questo NON rappresenta la formazione di mitocondri, nucleo o una cellula eucariotica; l'aggregazione procariotica resta facoltativa per la storia evolutiva generale.

## Come giocare
- Joystick virtuale (Android) oppure WASD/frecce (desktop): movimento.
- Raggiungi i nutrienti e premi **SCISSIONE** quando risorse e ATP raggiungono la soglia.
- Scegli una delle due figlie; la sorella resta nel mondo come NPC.
- Scegli la variante con DNA stabile e successivamente la discendente Archaea.
- Sulle generazioni Archaea seleziona progressivamente **recettori** e **trasportatori** come mutazioni maggiori.
- Segui l'indicatore **BACTERIA** sullo schermo. Avvicinati e premi **COOPERA**.
- Mantieni il contatto mentre avviene lo scambio, raccogli di nuovo i nutrienti consumati e dividi la linea associata per completare Fase 2.
- **CELLULA** apre la vista ravvicinata; **MENU** contiene **Come giocare**, **Fase 2**, **GENOMA**, **Obiettivi**, **ALBERO**, **LINEE**, **SALVA** e **CARICA**.

I salvataggi usano il formato logico v70; la lettura delle partite v67 precedenti è supportata con migrazione controllata dei campi genetici e di consorzio, senza attribuire retroattivamente mutazioni mai osservate.

## Build e grafica
- Android ARM64, **Godot Mobile/Vulkan** e APK alternativo **GL Compatibility**. Il progetto usa `mobile` come renderer predefinito e `gl_compatibility` sul Web.
- I sei asset Blender GLB reali, sotto `assets/models/`, sono creati in modo riproducibile con `tools/blender/create_cell_assets.py`.
- Lo shader della membrana è in `shaders/cell_membrane.gdshader`; qualità grafica ancora soggetta a iterazioni. La build non è una produzione fotorealistica.
- L'APK di prova usa un **package differente** da `demo-6`, per non sovrascrivere la vecchia installazione.
- Nessun multiplayer né permesso INTERNET: Nakama è riservato a una fase futura.
- MCP Godot resta uno strumento **editor-only**. Configurazione sicura: [Guida di sviluppo](docs/DEVELOPMENT_BLENDER_GODOT_MCP.md).

## Verifiche automatizzate
Il workflow `.github/workflows/validate-remaster.yml` esegue:
- validazione glTF dei modelli reali Blender;
- controlli statici e parsing Godot;
- smoke test di scissione, genealogia, salvataggi e genoma;
- test della progressione Fase 2 dall'adesione fino alla figlia;
- **test completo della campagna dalla primordiale fino alla Fase 2**;
- catture autentiche da Godot GL e Vulkan;
- esportazione e ispezione degli APK Android, senza rilascio pubblico automatico.

La pipeline di Blender è in `.github/workflows/bake-cell-assets.yml`.

**Limiti:** animazioni/asset e resa scientifica restano semplificazioni 3D; non è un simulatore molecolare. I test CI non equivalgono a una prova di prestazioni o compatibilità su smartphone fisico.

## Sicurezza
Non committare keystore, token MCP, `.mcp.json` o credenziali Nakama. L'APK di preview è firmato come build debug e potrebbe richiedere reinstallazione tra run, in caso di certificato differente.
