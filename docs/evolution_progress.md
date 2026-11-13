# Progressione funzionale fino al LECA

EvolutionProgress e puro: non modifica il wallet. Il chiamante controlla e addebita i costi del catalogue solamente dopo acquisto riuscito. can_unlock verifica capacita, divisioni ed evidenza; unlock restituisce nuovo stato oppure stato normalizzato invariato. origin, normalize, on_division, status non mutano l'input.

Il salvataggio conserva campi sconosciuti e stato legacy separati. I vecchi flag stable/transmitted/complete non sbloccano capacita: consorzio esterno non implica endosimbiosi. Bacteria e Archaea sono alternative esclusive nella singola linea; il percorso archaeale non richiede il ramo Bacteria. Il partner batterico e una linea esterna.

Chiamare on_division una volta per divisione della linea controllata; fornire division_id stabile per deduplicare consegne consecutive dello stesso evento. Non chiamarlo per ogni figlia o NPC. Nessun timer idle conferisce avanzamento. traits in can_unlock e riservato all'integrazione; i prerequisiti sono gli unlock espliciti.

Contesto esterno: external_partner_alive, partner_id non vuoto, partner_branch=bacteria, exchange_active. Tre divisioni consecutive dello stesso partner permettono consorzio stabile; sei permettono ingresso insieme al traffico di membrane, dopo divisione 38. Conteggio dal citoscheletro sbloccato. Partner/scambio assente azzera stabilita, cambio partner riparte da uno. Derivare questi valori dalla simulazione.

Contesto interno: internal_transmitted significa trasmissione osservata dell'organismo interno alle figlie, dopo acquisizione esplicita di internal_symbiont. Mitocondrio richiede sei trasmissioni consecutive e quattro con protein_import, metabolic_integration, coordinated_division. Non richiede la presenza del vecchio partner esterno. LECA richiede mitocondrio, nucleo, RE-Golgi e otto divisioni consecutive con funzioni integrate, membrane_traffic_functional e nuclear_transport_functional, oltre a 60 divisioni totali. Traguardi acquisiti restano registrati se la stabilita corrente viene persa.

can_unlock usa il contesto fornito quando non vuoto. unlock(state,id) rilegge evidenza dell'ultima divisione: prima di acquistare il chiamante DEVE verificare contesto vivo con can_unlock, oppure aggiornare state.evidence con dati correnti. Il modulo puro non osserva un partner morto fra divisioni. Per partner assente passare external_partner_alive=false, non dizionario vuoto.

Soglie numeriche GAMEPLAY. Confidence riguarda la descrizione biologica, non la cronologia deterministica. Protocellula narrativa, LUCA ricostruito, Asgard moderni come analoghi; ordine di ingresso/nucleo/membrane incerto. DAG permette nucleo/RE-Golgi parallelamente alla maturazione del simbionte. Golgi non nasce da lisi del partner. PhaseOneProgress e PhaseTwoProgress restano distinti e non modificati.

Test Godot headless: res://tests/evolution_progress_smoke.gd. Percorso archaeale raggiunge LECA senza Bacteria, almeno 60 divisioni, contesti e migrazione verificati. Non misura durata o raggiungibilita nel mondo reale.
