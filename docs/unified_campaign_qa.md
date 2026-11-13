# QA integrazione campagna unificata

Test `tests/unified_campaign_smoke.gd`: prima divisione tramite animazione reale, poi progressione accelerata attraverso i veri handler `_choose_daughter` e `_unlock_capability`. Risorse ed eta riproduttiva sono riempite esplicitamente; il donor e un'entita reale ma stabilita/scambio esterni sono fixture forzate. Il test non dimostra durata naturale, comportamento autonomo del partner o bilanciamento sul lungo periodo.

Verifica entrambe le figlie con genoma identico, assenza menu varianti, soglie 35/75 secondi, 2 PM base e frazione .375, costi del wallet unico, percorso archaeale senza ramo Bacteria, 60+ divisioni per LECA, rimozione donor e provenienza endosimbiotica, due roundtrip moderni e due dopo migrazione sintetica v71. La migrazione rimuove esplicitamente stato evolutivo/ecotipo/eta e censimento nuovi; non deve inventare un simbionte interno da tratti o flag di associazione.

Esecuzione Godot headless con APPDATA/LOCALAPPDATA isolati sotto `.tools/unified_campaign_test/`. Output PASS atteso, codice uscita 0; ogni controllo fallito incrementa contatore ed esce 1. Errori runtime richiedono controllo separato del log e watchdog dell'esecutore.

Esito verificato: **PASS**, Godot 4.7.2 headless, codice 0, run finale isolato in `.tools/unified_campaign_test3/`. LECA raggiunto attraverso handler reali dopo almeno 60 divisioni. Nessun bug runtime rilevato dal test; il messaggio ambientale sul certificate store non interrompe l'esecuzione.

I confronti di persistenza sono semantici: JSON converte interi non tipizzati in float equivalenti, mentre la normalizzazione del censimento materializza crediti zero assenti. Entrambe le forme sono normalizzate prima del confronto. Sono presenti crediti ecologici non zero .375/.625 per verificare che la normalizzazione non nasconda perdita di frazioni effettive.
