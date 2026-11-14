# Espansione 0.84 · incrementi verificabili

Base verificata: 0025aa4, ramo work/first-mutation-arena-083, nessun seguito remoto su quel ramo al controllo iniziale. Il lavoro prosegue in work/living-niches-084.

## 1. Insediamento e sorelle

Mappa facoltativa da META o MENU anche dopo aver saltato la guida. Tre habitat sono partizioni locali del censimento: non si sommano due volte al settore centrale. La superficie cartografica totale resta5,29km². Esistono25 settori di fondo e3 siti locali, con capacità portante propria; la soglia ludica di consolidamento rimane7 individui, più20s configurabili. Numeri di densità non equivalgono a una scala biologica reale.

I template delle cellule dematerializzate conservano genoma, wallet, acquisti, capacità, legami e posizione. La popolazione viva nel censimento determina se possono essere materializzate, senza aggiungere nascite. Le nuove rappresentanti delle nascite aggregate hanno una provenienza di linea e generazione fondatrice, non la generazione del giocatore. Una coorte estinta non viene resuscitata dal controllo genealogico.

Verifiche: percorso prima digestione preesistente; settlement_sisters_smoke usa scissione reale e comandi di albero/genealogia con risorse e maturità predisposte per isolare il comportamento. Copre divergenza, cambio controllo, dematerializzazione, salvataggio e ritorno a conteggio invariato; sei divisioni NPC reali raggiungono7 fondatori e la verifica di persistenza. Non è una misura del tempo naturale necessario a fondare una colonia.

## Incremento 2 — eventi locali
Dormienza acquistabile (2 PM dopo ereditarietà RNA): ingresso 8 ATP, costo 4, riposo minimo 12 s, consumo basale al 15%. Risveglio automatico con ATP >=18, carbonio >=8 e temperatura <=39; uscita manuale dopo 12 s. Nessuna immunità alla temperatura o alla morte per ATP esaurito. Le dormienti restano individui simulati anche fuori schermo, esclusi dalla crescita delle coorti.
Dopo digestioni in due generazioni, una figlia rivale locale può ereditare idrolasi con un costo di assorbimento; deve pagare ATP e consumare le stesse porzioni del giocatore.
La corrente parte 20 s dopo la prima digestione e ritorna ogni 150 s: sposta 12 particelle esistenti per 18 s, depone metà al termine; adesione riduce la deriva. ID persistenti impediscono duplicati e conservano il tragitto dopo caricamento.
Verifica `campaign_events_smoke.gd`: comandi dormienza/risveglio, blocco movimento/scissione, conservazione particelle e caricamento al secondo 7, discendenza rivale e digestione concorrente con cooldown. Fixture accelerata: nessuna osservazione di playtest umano.

## Incremento 3 — percorsi collettivi
Aggregati procariotici nel ramo batterico: la scissione collega le figlie mediante giunzioni; velocità 72% in acqua libera. Gruppi differenziati alterna adesione (58% velocità, 88% assorbimento) e assorbimento (108%); sul tappeto la presenza di ruoli complementari dà 22% di raccolta aggiuntiva e minore deriva. Frammentazione dal MENU: sposta individui esistenti e mantiene le rispettive genealogie. I componenti restano simulati, non vengono ricreati tornando nell'area.
Due popolazioni donatrici indipendenti sono inizializzate nella piana e sul tappeto; la ricerca non genera più un batterio vicino al giocatore. La mappa mostra una rappresentante compatibile e la provenienza interna. Riutilizzati adesione, trasportatori, costi di scambio, stabilità su divisioni, organelli distinti e pista delle endomembrane.
`collectives_smoke.gd`: scissione normale con animazione, ruoli e frammentazione conservativa, salvataggio; incontro con donatore esistente, COOPERA e 30 secondi di scambio simulato, ingresso tramite acquisto normale e provenienza al caricamento. Prerequisiti e stabilità sulle generazioni accelerati: non è una misura del percorso naturale fino al mitocondrio.

## Incremento 4 — fronti e combattimento
Nuova partita salva `front_version=2`: ogni fronte offre 2 punti anticipo e 3 per assorbimento effettivo dal deposito R conteso nei primi 45 s oppure attraversamento con alleato nella finestra già esistente. Quote indipendenti, una volta ciascuna; vecchie partite senza versione restano con il bonus unico 5. Riepilogo separa anticipo e scelta attiva.
Attacco condiviso: preavviso 0,7 s, portata 1,65, costo 10 ATP, potenza 18, recupero 1,8 s. Direzione iniziale vincolata; uscire dalla portata o dal cono evita danno e credito. Simbolo triangolare pulsante durante preparazione e puntini in recupero. Difesa può contrattaccare, Mobilità evade, Cooperazione contrattacca vicino al partner. Parametri e attacchi in corso salvati. Nessuna copertura geometrica delle rocce dichiarata.
Verifiche `battle_active_combat_smoke.gd` e `battle_scoring_smoke.gd`: doppia quota senza duplicati, raccolta a riserve piene esclusa, deposito sicuro escluso, salvataggio durante preavviso, schivata senza danni/credito, contrattacco, attribuzione multiattaccante, morte ambientale, finale senza eliminazioni e fixture dove i soli crediti di eliminazione cambiano vincitore.

## Consegna e limiti
Controlli locali: 185 contratti statici, 6 GLB validi, 35/35 smoke Godot. Report arena: [confronto 0.83/0.84](BATTLE_ROYALE_084.md). Schermate riproducibili nel motore: `tests/capture_expansion_084.gd`, output `build/previews/084-{map,filament,consortium,front,result}.png`. Le scene per cattura sono predisposte, non sessioni umane.
[Protocollo playtest](PLAYTEST_084.md): preparato, non ancora eseguito con partecipante. Nessun test su telefono fisico. Restano da misurare FPS/termica e leggibilità touch, ritmi di reazione, progressione naturale completa e stabilità di molte colonie a lungo termine. Il percorso fino al mitocondrio è coperto dalla suite accelerata preesistente, l'incontro/scambio/ingresso dai nuovi comandi di integrazione.
La mappa mostra i nutrienti realmente presenti al momento dell'apertura. L'esplorazione lontana conserva il cibo delle popolazioni donatrici e garantisce un minimo locale entro un tetto di 124 particelle. La camera segue il centro del filamento. Le soglie cartografiche e la coesistenza con donatori già differenziati sono astrazioni del mondo di gioco.
