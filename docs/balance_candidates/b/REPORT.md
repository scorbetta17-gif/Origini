# Alternativa B — Specialisti ecologici

Proposta indipendente del 13 novembre 2026. Solo esperimento numerico: nessuna modifica al runtime, ai salvataggi o alle due fasi. Consultati master del 12 novembre, dossier scientifico del 13 novembre, `mutation_balance.gd`, `cell_physiology.gd`, `cell_genome.gd` e test di bilanciamento esistenti. Ramo verificato: `work/ocean-cell-tree`, non main.

## Regola riproducibile

Investimento `x_s` = punti effettivamente assegnati al ramo della statistica, inclusi gli equivalenti dichiarati dei nodi maggiori. Per ogni statistica s:

`s = clamp(1 + gain_s*(1-exp(-x_s/20)) - sum_t(coef[t][s]*(x_t/40)^1.3), floor_s, cap_s)`.

Coefficienti completi in `config.json`. Ricalcolo dall'investimento cumulato: ordine degli acquisti irrilevante, impossibile cancellare un malus comprando dopo il suo opposto. Il costo marginale sale prima del limite minimo, poi il limite protegge la giocabilità. Raggiunto un tetto, ulteriore investimento non porta beneficio ma continua a creare costi: UI deve mostrare anteprima e avvertimento, non permettere acquisti numerici inutili senza una capacità funzionale collegata.

`vitality` moltiplica HP massimi; `defense` riduce separatamente il danno. La formula del danno deve evitare immunità: proposta danno ricevuto = danno base * attacco attaccante / difesa difensore, con cooldown e ATP sempre pagati. Non implementata o simulata qui. Mobilità conserva costi energetici del movimento; metabolismo non significa energia gratuita. Il cap mobilità B=1,65 richiederebbe aggiornare esplicitamente il clamp attuale 1,60 di CellPhysiology. La propensione attuale `mutation` parte da zero e rappresenta altro: migrare in un nuovo campo `mutation_point_multiplier`, non reinterpretare silenziosamente il vecchio valore.

## Divisione, albero e identità

Ogni divisione conclusa della linea controllata accredita `2 * multiplier` punti, con resto frazionario persistente. Multiplier nell'intervallo 1..1,5. Nessun premio per divisioni NPC: impedisce crescita esponenziale della valuta. Figlie ereditano lo stesso investimento e i loci della madre; nessun selettore di varianti casuali. L'albero a percorsi permette scelta esplicita di nodi minori, capacità maggiori con prerequisiti funzionali e nodi di specializzazione incompatibili quando necessario. I rami batterico e archeale restano distinti; usare i loci esistenti e le regole di espressione di CellGenome, conservando storia dei geni e migrazione legacy. Le associazioni ecologiche del dossier non diventano automaticamente simbiosi o organelli.

| Specialista, budget 80 | Vantaggio | Compromesso numerico |
|---|---|---|
| Predatore | attacco 1,90; HP 1,44 | assorbimento 0,59; metabolismo 0,64 |
| Difensore | difesa 1,80; HP 1,64 | mobilità 0,55; metabolismo 0,84 |
| Raccoglitore | assorbimento 1,75; metabolismo 1,57 | difesa 0,61; attacco 0,68 |
| Dispersore | mobilità 1,65 | difesa 0,80; nessun vantaggio di raccolta |

## Nicchie e campagna

Una nicchia è un'area fisica persistente in km², indipendente da camera e raggio di rendering. Per ogni lignaggio conteggiare cellule vive: densità `own/area >=30`; dominio `own >=1,5*max(rivali)`. Con zero rivali vale solo la soglia di densità. Non sommare i rivali, non usare percentuale della popolazione totale. Proposta stabilizzazione: condizioni vere per tre divisioni della linea e almeno 180 secondi nella nicchia; caduta delle condizioni sospende il conteggio, da decidere se azzerarlo dopo una tolleranza di 30s. Questi tempi sono ipotesi progettuali, non testati nell'esperimento.

240 punti di percorso principale, 2 punti base/divisione, 180–300 secondi per divisione e 45–90 minuti aggiuntivi di esplorazione/stabilizzazione danno 285–690 minuti analitici (4h45–11h30). Il limite veloce concede ottimisticamente subito il moltiplicatore massimo e zero costo della sua acquisizione. Le attività aggiuntive sono considerate sequenziali; se sovrapposte il tempo scende. Sono obiettivi di tuning, NON durata misurata. Nessun ritardo obbligatorio va aggiunto solo per gonfiare la durata: servono capacità, ostacoli e nicchie differenti. Il budget finale 240 non obbliga a comprare tutti i rami; le statistiche sature favoriscono nuove funzioni.

## Esperimento eseguito

Da `game/`: `python docs/balance_candidates/b/experiment.py` (Python standard, seed 20261113). Scrive `results.json` solo in questa cartella. Eseguito con exit 0: 12.545 build, cinque budget 10/40/80/160/240, cinque habitat, nove archetipi e 2.500 allocazioni casuali per budget. Tutti i limiti rispettati; sette casi di confine della densità/dominio passano. Per ogni budget ci sono cinque vincitori distinti nei cinque habitat; ogni archetipo ha almeno un concorrente migliore in almeno un habitat.

Gli habitat usano una media geometrica pesata delle statistiche; i pesi sono espliciti nel sorgente. Perciò il test misura diversificazione di efficienza ambientale in un modello scelto: NON prova l'esito di combattimenti, sopravvivenza, capacità di ottenere densità 30 o vittoria su NPC reali. Le allocazioni casuali sono continue e ignorano i prerequisiti dell'albero; alcune non saranno acquistabili. Il test non sostituisce Godot/Android né un playthrough.

Limite rilevato: 1.117/725/471/210/53 build ai rispettivi budget migliorano tutte e sette le statistiche rispetto alla partenza. Quindi il generalista può migliorare globalmente; non domina però tutti gli habitat nel campione. Se «nessuna super-cellula» significa proibire anche qualsiasi miglioramento globale, questa alternativa non soddisfa quella lettura e richiede vincoli di capacità incompatibili o un tetto al budget fisiologico attivo. Raccomando invece la definizione verificabile: nessuna build domina le altre in ogni habitat, mantenendo generalisti giocabili. Il modello non dimostra tale proprietà per tutte le possibili allocazioni, soltanto per il campione.

Prima dell'adozione: simulare acquisizioni reali dell'albero e punti nel tempo; combattimenti, ATP, raccolta, densità per area; testare salvataggi storici; misurare campagna con utenti. L'esperimento B suggerisce specializzazioni leggibili e costose, ma le cifre finali dipendono dalle risorse distribuite nel mondo e dal comportamento degli NPC.
