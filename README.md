# ORIGINI — dalla Cellula Zero al grado LECA

Revisione 0.81: cellule ovoidali, DNA viola a gomitolo, flagelli elicoidali e statistiche delle popolazioni. [Dettagli e verifiche](docs/CELL_STATS_081.md).

Prototipo Godot 4.7.2 per desktop e Android ARM64. La versione 0.80 introduce una campagna continua: scissione animata, punti mutazione, specializzazioni con bonus e malus, nicchie persistenti e capacità cellulari fino al grado LECA.

- 336 nodi di specializzazione e 23 capacità evolutive con prerequisiti.
- Tre alternative di bilanciamento confrontate; build B con capacità finita integrata.
- Mappa cartografica di 5,29 km² e 25 nicchie con densità, coesistenza e dominanza.
- Consorzio esterno, simbionte interno e mitocondrio funzionale distinti; nucleo e RE-Golgi paralleli.
- Migrazione dei salvataggi precedenti; nessuna selezione casuale delle figlie per il giocatore.

[Comportamento, limiti scientifici, ritmo e verifiche](docs/UNIFIED_CAMPAIGN_080.md) · [Confronto dei tre bilanciamenti](docs/balance_candidates/COMPARISON.md).

Aprire `project.godot` con Godot 4.7.2 e avviare `scenes/Main.tscn`. Movimento WASD/frecce o joystick; DIVIDI quando maturità, ATP e nutrienti sono sufficienti; EVOLUZIONE per spendere PM; CAPACITÀ per scegliere il percorso; META per le nicchie; MENU / Statistiche e popolazioni per censimento RNA/DNA e contatori; MENU per salvataggi e genealogia.

Test: `python tests/run_suite.py --timeout 180` (Godot portatile rilevato automaticamente oppure `--godot godot`). `python tests/qa_static.py` controlla i contratti statici. I test accelerati fino a LECA non misurano la durata di una partita naturale; il dispositivo Android fisico resta da provare.

Le vecchie note a due fasi sono conservate come [documentazione storica 0.79](docs/README_PRE_UNIFIED_079.md), superata dalla direzione attuale.
