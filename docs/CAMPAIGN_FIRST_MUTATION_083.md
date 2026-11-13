# Passaggio 1 · guida e habitat 0.83

Base: a23ae8a, successore compatibile di d63e14a. Guida opzionale salvata nel campo `journey`, senza cambiare il formato 80. I salvataggi precedenti con almeno una divisione non ripartono dal tutorial.

Nuova partita senza introduzione bloccante: obiettivo singolo, nutriente utile evidenziato, motivo effettivo del blocco scissione. Dopo la divisione: offerta del nodo 88 (idrolasi, 2 PM), acquisto con il validatore ordinario, confronto dei due fenotipi 3D, detrito entro 3,5 unità orizzontali. Digestione normale: 6 ATP, porzioni finite, riserve limitate. La guida può essere saltata; conservare i PM non impedisce acquisti successivi. I pannelli completi restano accessibili dal menu e dall'albero. Corretto il criterio di distanza dei detriti: la quota del fondale non deve rendere irraggiungibile un bersaglio nella stessa posizione orizzontale.

Tre habitat locali nella mappa esistente di 5,29 km² cartografici (scala ludica, non dimensioni realistiche delle cellule):
- Piana (0,5): raggio distribuzione 7, nessun concorrente aggiunto, temperatura sotto 40 °C.
- Faglia (16,-14): fonte termica preesistente, cibo tra 2,2 e 4,8 unità dalla fonte; gradiente reale. A (18,5,-14) circa 60 °C: soglia iniziale 43, tolleranza 1,5 porta la soglia a 70. Il centro resta pericoloso anche per numerosi adattamenti.
- Tappeto (-15,-9): raggio 3,2, 22 particelle iniziali e tre foraggiatori reali che consumano le medesime risorse. Nessun respawn gratuito dei concorrenti.

Tutti raggiungibili in meno di 15 secondi di movimento iniziale senza ostacoli. Il rifornimento vicino all'origine mescola le tre aree con il sistema esistente; lontano resta la generazione del mondo esteso. I controlli `campaign_journey_smoke.gd` e `unified_foraging_smoke.gd` verificano il primo utilizzo senza concedere risorse, PM o maturità, il singolo addebito, la ripresa, la guida saltata e la migrazione legacy. Il secondo completa tre scissioni con cibo realmente raccolto.
