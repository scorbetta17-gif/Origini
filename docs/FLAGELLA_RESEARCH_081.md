# Flagelli e archaella — ricerca per la revisione 0.81

Ricerca online del 13 novembre 2026; fonti primarie strutturali e sperimentali. Sono state consultate le descrizioni indicizzate degli articoli e le sezioni disponibili tramite ricerca. L'apertura diretta di alcune pagine Nature/PMC ha incontrato redirect o CAPTCHA: non si dichiara una lettura integrale di tutti i lavori.

## Struttura e movimento

Un flagello batterico non è un tentacolo che frusta l'acqua. Il lungo filamento ha forma elicoidale e viene fatto ruotare dal motore basale; un corto raccordo curvo, l'hook, collega il filamento al corpo basale. La struttura dell'hook spiega come trasmetta coppia pur permettendo di cambiare orientamento. Nei batteri con più flagelli questi possono raccogliersi in un fascio durante il nuoto, ma non tutte le specie possiedono la stessa disposizione. [Kato et al., 2019, struttura cryo-EM dell'hook](https://www.nature.com/articles/s41467-019-13252-9).

Il motore e il sistema che ne controlla il senso di rotazione sono complessi inseriti nell'involucro: non un grosso pomello appeso fuori dalla cellula. È quindi ragionevole rendere visibile soltanto una piccola sede di inserzione nella vista di gioco. [Studio cryo-EM del motore e della commutazione, 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11087270/).

L'archaellum degli Archaea è anch'esso un propulsore rotante, ma appartiene a una macchina molecolare diversa. Il motore usa ATP e il filamento è composto da archaelline, assemblate alla base. Lo studio di *Methanocaldococcus villosus* mostra un filamento di circa 11 nm di diametro con subunità alternate; non è un diametro universale. Alcune specie presentano una regione basale simile per aspetto a un hook, altre no: non copiare automaticamente l'intero hook batterico sugli Archaea. La distinzione fra flagello e archaellum deve restare nel genoma e nel modello. [Gambelli et al., 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC8821640/).

Questi propulsori non giustificano un'animazione da ciglio eucariotico: per le due strutture considerate qui, la rotazione di un'elica è la scelta visiva appropriata.

## Adesione

I flagelli possono contribuire anche all'adesione: esperimenti su superfici topografiche mostrano che i filamenti aiutano l'attacco alla superficie. Ciò non dimostra che ogni flagello sia un'adesina universale o che un flagello dedicato all'adesione conservi automaticamente tutta la spinta propulsiva. [Friedlander et al., 2013](https://pubmed.ncbi.nlm.nih.gov/23509269/).

Nel gioco conviene mantenere separati capacità genetica, stato ancorato e motilità effettiva. L'eventuale riduzione di velocità quando la cellula aderisce è una regola di bilanciamento; non assegnarle un coefficiente dichiarato come misura biologica.

## Applicazione al renderer esistente

Il codice `src/cell_visual.gd` già ruota i filamenti attorno all'asse lungo e distingue i due tipi. Il difetto visivo è soprattutto la geometria: 23 campioni per 2,6–3,6 spire, tubo relativamente spesso, attacco del primo punto spostato rispetto alla base. Il risultato sembra una molla corta e rigida.

Proposta artistica economica, da verificare in una cattura Godot:

- Separare piccola base, raccordo corto e filamento. Tenere l'inserzione ancorata alla membrana e animare il filamento senza far orbitare l'intero punto d'attacco.
- Usare 48–64 campioni per un'elica più aperta, circa 1,5–2 spire visibili, lunga circa 2–3 diametri cellulari. Sono proporzioni di leggibilità, non ricostruzioni di una specie.
- Ridurre il raggio del tubo indicativamente a 0,012–0,018 unità della scena; mantenere l'archaellum visivamente più sottile. Non rendere la punta una lama.
- In `_tube`, 6 sezioni radiali bastano normalmente per un filamento sottile: 64 campioni producono circa 756 triangoli. Con l'attuale sezione da 10 lati sono circa 1260 triangoli; evitare di ricostruire la mesh a ogni frame.
- Creare la mesh una sola volta e animare il transform con una fase continua. Velocità di rotazione, colori, numero massimo rappresentato e ingrandimento del raccordo sono convenzioni artistiche.
- Per cellule biflagellate usare due inserzioni distinguibili, non una sovrapposizione perfetta. Mostrare l'ovale cellulare senza attribuire a tutte le linee una morfologia identica in natura.

Nessun file runtime modificato da questa ricerca.
