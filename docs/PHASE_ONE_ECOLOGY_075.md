# ORIGINI — Bilanciamento e missioni Fase 1 (sviluppo successivo a 0.74)

Questa iterazione e' **solo sorgente**: nessun nuovo APK viene compilato automaticamente.
Restano immutate la Fase 2 come consorzio procariotico, la genealogia, la grafica
2.5D classica e la vista cellulare Blender 3D.

## Movimento e fisiologia
- Velocita' non motile del giocatore: da `3.40*0.78 = 2.652` a
  `3.40*0.90*0.78 = 2.3868` unita'/s (**-10%**).
- Velocita' NPC senza motori: da `1.0` a `0.9` unita'/s (**-10%**),
  poi specializzazione e locomotori danno bonus biologicamente acquisiti.
- NPC: decisione/target ogni ~0.22 s, *interpolazione a ogni frame*; acelerazione
  limitata da `NPC_ACCELERATION`. Ogni figlia parte con velocita' nulla e
  accelera, senza teletrasporto.
- ATP: manutenzione 0.28 ATP/s per la cellula giocata; movimento 0.55 ATP
  per unita' di distanza (modulato dall'efficienza metabolica). Anche gli NPC
  pagano mantenimento e distanza. Quando ATP=0, moto e azioni cessano. Nutrienti
  vicini possono rigenerare ATP; in assenza di nutrienti si raggiunge morte
  dopo 15 secondi a zero.
- Attacchi, rigenerazione e cooperazione richiedono ATP disponibile.
- Dimensione fisica e sagoma 2.5D: 1.00x alla nascita, fino a **1.20x**
  quando la biomassa raggiunge la soglia per dividersi. L'ulteriore nutrizione
  non fa crescere oltre.
- Riserva massima per carbonio, amminoacidi, lipidi, nucleotidi e biomassa:
  `1.12x` la soglia di divisione (**+12%**). Un organismo con riserve piene
  puo' ancora assorbire materiale per ATP se e' in deficit energetico.
- Nutrienti iniziali: 76 → **84** (+10.5%); cap nell'ambiente: 85 → **94**
  (+10.6%). Distribuzione attorno all'origine e in ambiente remoto.

## IA autonoma e pressione selettiva
- Le cellule non controllate accumulano nutrienti e biomassa e si dividono
  autonomamente quando età >=18 s, biomassa >=57, energia >=23 e c'e' spazio
  nella popolazione (max 32 corpi viventi in questa simulazione).
- Ogni divisione produce 2 figlie realmente distinte, con genoma, ATP e parte
  delle riserve ereditarie; la genealogia mantiene entrambi i rami.
- Evoluzione autonoma: da protocellula verso LUCA/DNA e successivamente
  verso linee sorelle Bacteria o Archaea, con probabilità esplicita per
  divisione. Archaea non si trasforma in Bacteria.
- Ecotipi: raccoglitori; esploratori con pili/motori che fuggono dai predatori;
  predatori lenti con proteasi; difensori con EPS/stat difensive. Predazione e
  pressione energetica determinano crescita o estinzione. Le specializzazioni
  maggiori richiedono loci ereditabili, non bonus numerici arbitrari.
- Non e' una stima validata di tassi riproduttivi della Terra primordiale:
  le soglie sono parametri di gameplay da ribilanciare dopo prova sul dispositivo.

## Fasi e missioni

### Fase 1 — conquista della nicchia
All'avvio di una nuova partita: pannello a schermo intero con missioni e
comando **INIZIA FASE 1**. Traguardi:
1. Prima scissione controllata;
2. Linea del giocatore al ciclo/generazione 6;
3. almeno 3 divisioni **autonome** delle altre cellule;
4. almeno 10 cellule contemporaneamente vive;
5. competizione osservata per **75 secondi continui**, col popolamento
   minimo sopra soglia.

Il conteggio si congela in un rapporto all'inizio e alla fine dei 75 s. Il
rapporto mostra quote delle coorti: **prime (gen 0–2)**, **intermedie (3–5)**,
**recenti (6+)**, più quattro tipi di comportamento.
Nessuna categoria ha un vantaggio di quota imposto dal codice; e' possibile
che intermedie restino dominanti o che recenti superino le altre. Il delta di
quota rappresenta una differenza demografica osservata, non prova automatica
di fitness superiore o vantaggio genetico.

### Fase 2 — cooperazione
Quando le missioni precedenti sono complete, si presenta una **nuova schermata
di apertura**, con il censimento della Fase 1 e le missioni dedicate alla
cooperazione Archaea/Bacteria già sviluppate: adesione, metaboliti, consorzio
stabile e trasmissione alla figlia. L'associazione batterica non compare come
missione intermedia della Fase 1; l'endosimbiosi e' rinviata.

## Albero evolutivo
Zoom base da 0.9 a 1.22; zoom max 3x, hitbox touch maggiorata. I 6 tipi di
nodi maggiori hanno simboli vettoriali specifici: motilita', attacco, difesa,
ereditarieta', energia, trasporto. I nodi piccoli restano modificatori
quantitativi; i nodi grandi **sbloccano anche loci ereditabili** con
fenotipo biologico.

## Salvataggio e prove
Il formato interno passa a **v71** (sempre in `user://origini_067.json`)
e mantiene il caricamento di v67/v70. Salva fasi, censimenti, ATP zero e
stati di salute/energia di ogni linea. I test automatici verificano i limiti
numerici, riproduzione, moto interpolato, ere­ditarieta', missioni, report,
scissione, Fase 2 e UI. L'APK viene creato solo su **workflow_dispatch**
esplicito; non e' stato richiesto in questa iterazione.
