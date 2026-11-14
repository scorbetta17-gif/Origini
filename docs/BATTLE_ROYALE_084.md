# Simulazioni arena 0.84

12 partite con semi 8200–8202 e quattro profili del driver 0.83, dt 0,5 s. Simulazione accelerata, non playtest umano né benchmark telefono. La meccanica di contrattacco è eseguita anche per il giocatore pilotato dal driver.

| Seme | Profilo giocatore | Fine (s) | Esito | V/40 | N/20 | E/20 | Anticipo/8 | Attivo/12 | Totale | Primo superstite | Primo con formula 0.83 sugli stessi eventi |
|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|---|
|8200|Predazione|180.5|sconfitta|7.12|9.02|8|2|0|26.14|BR-011|BR-011|
|8200|Difesa|940.0|sconfitta|0.00|9.57|0|8|0|17.57|BR-004|BR-012|
|8200|Mobilità|1200.0|sconfitta|39.60|6.94|0|8|0|54.54|BR-001|BR-001|
|8200|Cooperazione|1200.0|vittoria|38.92|9.44|0|8|12|68.37|C-000|C-000|
|8201|Predazione|184.0|sconfitta|7.78|8.62|8|2|0|26.39|BR-012|BR-012|
|8201|Difesa|1200.0|sconfitta|32.93|9.50|0|8|0|50.42|BR-008|BR-002|
|8201|Mobilità|1200.0|sconfitta|39.76|6.94|0|8|0|54.70|BR-008|BR-002|
|8201|Cooperazione|1200.0|vittoria|39.56|8.71|4|8|9|69.27|C-000|C-000|
|8202|Predazione|1200.0|vittoria|38.14|11.12|12|8|3|72.27|C-000|C-000|
|8202|Difesa|1200.0|sconfitta|35.92|10.35|0|8|0|54.27|BR-008|BR-006|
|8202|Mobilità|1200.0|sconfitta|39.89|6.94|0|8|0|54.83|BR-008|BR-010|
|8202|Cooperazione|1200.0|vittoria|39.24|6.94|0|8|12|66.18|BR-003|BR-002|

Tempo limite: 9/12 (0.83: 11/12). Vittorie del giocatore per profilo: Predazione 1/3, Difesa 0/3, Mobilità 0/3, Cooperazione 3/3.

Fronti fra le 77 voci delle classifiche a tempo: 8/20: 50, 11/20: 11, 14/20: 3, 17/20: 7, 20/20: 6. Nella 0.83 tutte le 80 voci a tempo erano 20/20. Ora solo 6/77 raggiungono il massimo.

Scelte attive assegnate nel registro di tutte le cellule, incluse le eliminate: {'deposito appena attivato': 31, 'attraversamento con alleato': 89}. Ogni quota è assegnata una volta; non sono conteggi di semplici contatti.

Confronto sugli stessi eventi: `ranking_old_same_events` usa ora la formula 0.83 (non quella 0.82), con un registro parallelo dei vecchi obiettivi, inclusi assorbimenti nei depositi S/C. Cambia solo il calcolo del risultato, non risimula decisioni controfattuali. Per le partite terminate con morte del giocatore la prima riga dei superstiti è una classifica provvisoria, non una vittoria assegnata a fine tempo.

Casi riproducibili: Cooperazione, seme 8200, vince senza eliminazioni: 68,43 punti, 20/20 fronti. Predazione, seme 8202, vince con 72,27 punti; senza i suoi 12 punti da tre eliminazioni scende a 60,27, sotto BR-004 a 66,75. Questi sono esiti del driver completo, oltre alle fixture unitarie.

La soglia nutrizione resta 150 unità effettivamente entrate nelle quattro riserve: non si sommano biomassa/ATP. Con il nuovo combattimento il massimo non è automatico; nessun aumento della soglia è giustificato da questi 12 scenari. Predazione resta più rischiosa (due sconfitte intorno a 3 minuti); Difesa e Mobilità non vincono come giocatore in questo campione. Non si dichiara equilibrio generale dai soli dodici scenari.

Report integrale: [JSON](reports/084-battle-playthrough.json). Nessun evento non finito/NaN rilevato.
