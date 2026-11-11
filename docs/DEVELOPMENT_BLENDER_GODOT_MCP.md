# ORIGIN — pipeline Blender → Godot Mobile → Android (0.69 preview)

## Principio
Il gioco nasce in Godot; Blender produce **mesh 3D reali**, non immagini 2D o fotomontaggi.
La compatibilita' e la biologia del genoma restano in GDScript; gli asset modulari sono
vincolati ai loci maggiori e non ai semplici aumenti numerici delle statistiche.

## 1. Blender (gratuito)
Versione CI: pacchetto Blender per Ubuntu 24.04; script:
```bash
blender --background --factory-startup --python tools/blender/create_cell_assets.py
python3 tools/blender/validate_cell_assets.py
```
I sei GLB in `assets/models/` sono creati con Blender: `primordial_core.glb`,
`pili_module.glb`, `receptor_module.glb`, `protease_module.glb`,
`transporter_module.glb`, `vesicle_module.glb`.
Il nucleo grafico primordiale contiene **membrana, singolo ssRNA, tre complessi
autocatalitici**. Niente DNA, nucleo, apparati locomotori o organelli all'inizio.
Non e' una rappresentazione molecular-dynamics atomistica; e' un modello
3D macroscopico semplificato, coerente con la progressione ludica.

Il file di Blender e' riproducibile dallo script parametrico. Quando si aggiungono
nuovi loci strutturali, aggiornare sia il generatore Blender che
`src/cell_genome.gd` / `src/cell_visual.gd`, quindi eseguire test ereditari.

## 2. Godot 4.7
Il progetto usa `mobile` come renderer predefinito e Android:
il renderer Mobile richiede un backend RenderingDevice (tipicamente Vulkan).
Per HTML5 si conserva `gl_compatibility`.
Le ombre shader e i materiali cellulari sono in `shaders/`; il gene determina
se un oggetto 3D viene istanziato e quante copie di quel modulo appaiono.
`tests/blender_asset_smoke.gd` fallisce se il motore non usa realmente GLB.

**Nota:** su alcuni Android vecchi il fallback Vulkan → OpenGL puo' fallire.
Il workflow genera due APK di prova separati:
- `ORIGINI-VULKAN-PREVIEW.apk`, package `org.origini.mobile.preview.vulkan`
- `ORIGINI-COMPAT-PREVIEW.apk`, package `org.origini.mobile.preview.compat`

Entrambi hanno identificativi differenti da `demo-6`: non disinstallare la versione
di produzione, specialmente se contiene salvataggi.
Non considerare superati i test su hardware reale finche' non eseguiti su smartphone.
La firma debug CI puo' cambiare tra run; per aggiornamenti definitivi occorre
una chiave stabile custodita in GitHub Secrets.

## 3. MCP Godot — SOLO editor desktop (setup opt-in)
Plugin comunitario selezionato: [Godot MCP Toolkit](https://github.com/NPGameDev/godot-mcp-toolkit),
con bridge [Godot MCP Server](https://github.com/NPGameDev/godot-mcp-server).
Non e' un plugin ufficiale Godot Foundation. Supporta Godot desktop 4.2–4.7;
il client bridge necessita Node.js >= 22. MCP non sostituisce git, CI o i test.

Passaggi sull'editor locale:
1. Verificare release, licenza e sorgenti del plugin prima di installarlo.
2. Dall'Asset Store Godot, installare **Godot MCP Toolkit** nel progetto.
3. In `Project > Project Settings > Plugins`, abilitarlo.
4. Dal menu del plugin generare `.mcp.json` mediante la funzione di setup.
5. Con Node >= 22, collegare un client MCP locale usando il bridge
   `@npgamedev/godot-mcp-server` (preferire versione bloccata/pinnata e verificata).
6. Confermare che il dock del plugin dica `[MCPServer] listening` e che il client
   riesca a leggere l'albero scene in **read-only mode** prima di consentire scritture.
7. Solo dopo, autorizzare l'agente a cambiare scene/materiali, usando branch Git.

Il server si lega al solo `127.0.0.1` e usa token di sessione.
Per ispezioni sicure, `GODOT_MCP_READ_ONLY=1`; non esporre mai il server su internet.
Mantenere `.mcp.json`, token e registri di sessione fuori dal repository. Il plugin
non va distribuito nell'APK.

**Stato attuale:** documentazione e pipeline CI presenti; nessuna istanza di editor
desktop MCP e' stata autenticata in questa conversazione. Configurazione locale
resta da attivare sul PC dell'utente, quando desiderato.

## 4. Multiplayer futuro (non implementato)
Architettura proposta: Godot 4.7 client → Nakama open-source con server authoritative
per genomi, scissione, risorse e genealogia. Il client invia comandi, non decide
autonomamente mutazioni o risorse canoniche. In futuro predisporre:
- login/autenticazione e sessioni persistenti
- separazione delle transizioni biologiche pure dal rendering
- serialization versioned di genotipo, fenotipo e mondo
- test deterministici tra client e server

**Non installare Nakama adesso.** Il gioco attuale rimane offline e non richiede
il permesso Android INTERNET. Si puo' discutere il networking solo dopo la
validazione visuale e giocabile in locale.

## 5. Criteri di accettazione
- Import GLB reale nel motore, non soli placeholder GDScript.
- Mutazioni maggiori mostrano moduli 3D coerenti e passano alle due figlie.
- Mutazioni puntiformi minori non generano appendici dal nulla.
- Godot registra a runtime il metodo di rendering effettivo; test specifico Vulkan.
- Screenshot riprodotti da motore Godot, non da generatore di immagini.
- APK Android separato dalla demo corrente e testato in dispositivo prima del merge.

Riferimenti:
- Godot asset import: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
- Godot renderers: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- MCP Toolkit: https://godotengine.org/asset-library/asset/5375
