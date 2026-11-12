# Fondale e faglie — 12 novembre 2026

Prosegue la revisione dei vulcani. Le cinque nuove fotografie sono archiviate
senza modifiche in `../modello immagini/`, con indice e SHA-256. Sono riferimenti
artistici: i raggi solari raffigurati sono esclusi per richiesta esplicita.

## Risultato

- Fondale geometrico 512 x 512 unità; area esplorabile 480 x 480 contro 50 x 50:
  92,16 volte la superficie giocabile. Le unità sono quelle del gioco, non metri.
- 256 settori da 32 unità, 137.216 triangoli complessivi di terreno. Ogni settore
  ha un mesh del suolo e un MultiMesh di rocce, eliminabili dal frustum della camera.
  8.704 rocce istanziate condividono un solo modello sfaccettato. Le geometrie sono
  generate all'avvio, non caricate in streaming; il mondo è finito.
- Depressioni, terrazzamenti, depositi, placche minerali statiche, ghiaia e gruppi
  di massi. 72 polilinee di frattura: quattro siti originali, 34 faglie e 34 rami.
  Le incisioni abbassano davvero il terreno. Le quattro sorgenti di bolle restano
  innocue; nessun nuovo danno termico viene associato alle faglie lontane.
- Palette minerale condivisa da basalto vulcanico, rocce e sedimento. I due vulcani
  conservano cratere, lava, posizione e comportamento termico precedenti.
- Eliminati riflessi mobili e caustiche dallo shader del terreno. Luce ambientale
  e illuminazione diffusa leggono i volumi; non ci sono fasci volumetrici solari.

## Integrazione nel gioco

Limiti di movimento del giocatore e delle cellule autonome aggiornati. I nutrienti
abiotici oltre 40 unità dal giocatore vengono ricollocati localmente solo se non
sono entro 25 unità da una cellula viva. Resti biologici preservati; cap di 94 e
cadenza temporale invariati. Non si simula un ecosistema nuovo in ogni settore:
la mappa amplia l'esplorazione, non moltiplica automaticamente la popolazione.
Formato di salvataggio invariato; test di salvataggio/caricamento a (210, -210).

Il generatore usa seed propri: non consuma il RNG di genetica/nutrienti.
Il raccordo tra tessellazione fine centrale e settori esterni interpola gli stessi
bordi. Bolle, crepe superficiali e rocce usano l'altezza dei triangoli renderizzati.

## Verifiche locali

- 13 smoke test Godot 4.7.2 superati, incluse campagna completa e fasi 1/2.
- 100 controlli statici e sei asset GLB validati.
- Test dedicato: estensione, normali rivolte in alto, raccordi, varietà altimetrica,
  movimento oltre i vecchi limiti, nutrienti lontani, tutela risorse NPC e save/load.
- Catture effettive OpenGL Compatibility e Mobile/Vulkan su desktop NVIDIA.
  File in `build/previews/`: `seabed-start.png`, `seabed-fault.png`,
  `seabed-distant.png`, `seabed-map.png`, `seabed-gameplay.png`; prefisso `mobile-`
  per Vulkan. Sono frame Godot, non immagini generate o fotografie applicate al suolo.
- Dati dei test isolati sotto `.tools/`; nessuna sostituzione delle partite utente.

Il test locale ha misurato circa 4,12 unità di variazione altimetrica nei campioni.
Queste verifiche non equivalgono a un benchmark su telefono: memoria, avvio e FPS
Android fisici restano da misurare. Nessuna nuova APK o release in questa revisione.
