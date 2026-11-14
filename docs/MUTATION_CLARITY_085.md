# ORIGINI 0.85 — ritmo e revisione biologica

Base: 0.84, cb010f24. Incremento: work/mutation-clarity-085.

## Ritmo

Ogni scissione controllata assegna 4 PM di base, fino a 6 con il bonus esistente di adattabilità. Le frazioni e i punti già salvati rimangono validi; nessun accredito retroattivo. Le figlie seguono le regole di eredità già presenti.

| Risorsa | Prima | Ora |
| --- | ---: | ---: |
| Carbonio | 24 | 21.6 |
| Amminoacidi | 15 | 13.5 |
| Lipidi | 12 | 10.8 |
| Nucleotidi | 8 | 7.2 |
| Biomassa | 65 | 58.5 |

Capienza delle riserve conservata: abbassare la soglia non elimina scorte nei salvataggi. ATP, maturità, prerequisiti e costi dei nodi non cambiano. La soglia autonoma di biomassa degli NPC passa da 57 a 51.3, con lo stesso adeguamento nella ricerca del detrito. Questo intervento accelera gli acquisti e la raccolta necessaria, non il tempo di simulazione.

## Revisione completa del catalogo

40 identificatori coperti dal renderer comune `biological_symbols.gd`: 16 loci e 24 capacità. I 280 nodi puntiformi rimangono pallini; le 56 posizioni maggiori usano il simbolo del locus effettivo, anche quando sono livelli dello stesso carattere. Non sono 56 nuovi organelli.

| Loci revisionati | Convenzione verificata |
| --- | --- |
| rna_replicase, dna_stabilization | RNA arancione aperto; DNA viola ripiegato. La doppia elica non è usata come icona dell'RNA. |
| membrane_transport, surface_recognition | Passaggio attraverso membrana; recettore con ligando, senza forma di anticorpo. |
| pili_twitch, flagellar_motor, archaellar_motor | Appendici adesive/retrattili distinte dai filamenti rotanti; motori batterico e archeale distinti. |
| hydrolase_secretion | Sito catalitico e substrato separato; non denti o lame. |
| vesicle_pathway, eps_biosynthesis | Gemmazione membranosa; matrice extracellulare, non nuovo organello. |
| thermal_membrane, chaperone_complex | Composizione lipidica; complesso di ripiegamento proteico. Nessun organello termico. |
| cell_elongation, monoderm_envelope, diderm_envelope, archaeal_envelope | Forma; parete; involucro con membrana esterna; lipidi archeali ramificati. Un doppio strato non equivale a due membrane. |

| Capacità revisionate | Convenzione verificata |
| --- | --- |
| cell_zero, rna_inheritance, translation, dna_archive | Compartimento, RNA, ribosoma a due subunità con mRNA/peptide, archivio DNA: simboli separati. |
| dormancy, bioenergetics, luca | Pausa reversibile (non spora universale), gradiente di membrana, discendenza comune (non prima cellula). |
| bacteria, archaea, alpha_partner, asgard_host | Batterio, lipidi archeali, donatore batterico, ospite con protrusioni. Non sono ricostruzioni storiche certe. |
| prokaryotic_groups, differentiated_groups | Catena di cellule; ruoli diversi nella stessa catena. |
| cytoskeleton, membrane_traffic, er_golgi | Rete interna, vescicole, cisterne mature: stadi separati. |
| stable_consortium, internal_symbiont | Partner esterno e batterio interno, senza creste mitocondriali premature. |
| nucleus, protein_import, metabolic_integration, coordinated_division | Involucro nucleare doppio, importazione di catena proteica, scambio metabolico, segregazione coordinata. |
| mitochondrion, leca | Doppia membrana e creste; composizione di più organelli, non semplice icona del nucleo. |

Nel 3D i complessi globulari iniziali sono sostituiti da piccoli filamenti catalitici di RNA. I ribosomi compaiono con la traduzione; il citoscheletro con la capacità relativa. Il traffico iniziale mostra vescicole, non un Golgi prematuro. Il simbionte interno mostra materiale genetico; le creste restano riservate al mitocondrio. Aggiunto il secondo involucro nucleare. Conservati i moduli 3D già coerenti: trasportatori, recettori, idrolasi, involucri, flagelli e chaperoni.

Colori, dimensioni, DNA a gomitolo e simboli di funzione sono convenzioni didattiche. Il percorso eucariotico resta un modello di gioco con le etichette di incertezza già presenti. Non si pretende che le singole mutazioni creino istantaneamente apparati completi, né che i lipidi archeali siano tutti tetraeteri.

## Fonti primarie consultate

- [Aleksashin et al., 2019 — subunità e funzione ribosomiale](https://pmc.ncbi.nlm.nih.gov/articles/PMC6389949/): sostiene la distinzione fra RNA e apparato di traduzione, non la cronologia del gioco.
- [Visualizing chaperonin function in situ, 2024](https://pubmed.ncbi.nlm.nih.gov/39169181/): complesso proteico di ripiegamento, non organello membranoso.
- [A novel mechanism for the biogenesis of outer membrane vesicles, 2016](https://www.nature.com/articles/ncomms10515): origine membranosa delle vescicole batteriche; non prova del percorso ancestrale proposto.

## Verifiche

189 controlli statici; 6 asset GLB validi; suite precedente 35/35; nuovo test mutation_clarity 1/1. Copertura di tutti gli identificatori, costo -10%, eredità dei punti, scorte piene, fenotipi dei 16 loci, gating degli organelli e persistenza nelle suite esistenti.

La prova automatica di raccolta iniziale completa tre scissioni in 185.08 secondi simulati senza regalare risorse o maturità. Non è una misura di playtest umano né una promessa di durata della partita.

`tests/capture_mutation_clarity.gd` genera l'atlante reale Godot; `tests/capture_cell_models.gd` riprende RNA, DNA e cellula evoluta. Verifiche su telefono fisico e giudizio estetico del giocatore ancora da eseguire.
