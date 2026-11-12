# Cellule ridisegnate — 13 novembre 2026

Revisione visiva richiesta dopo la prova APK0.77. Il genoma e le regole di gioco non cambiano.

- Silhouette piu organiche e leggermente appiattite; membrane frontali con gradiente di volume, bordo morbido e riflesso controllato. Le onde restano limitate e condivise con gli ancoraggi dei moduli.
- RNA riprogettato come filamento leggibile con basi simboliche; DNA piu spesso, coppie di basi e RNA accessorio. Raccordi continui tra gli anelli delle mesh tubolari e normali radiali, senza fessure fra segmenti.
- Tre complessi catalitici iniziali ridistribuiti e ingranditi, palette viola/ambra/turchese leggibile anche nel fondale scuro. Materiale dedicato con illuminazione illustrativa stabile: non una rappresentazione cromatica molecolare reale.
- Rivestimenti con piccole regioni superficiali invece della vecchia griglia a meridiani e paralleli. Moduli superficiali ricolorati e filamenti motori piu visibili.
- Le schede delle figlie usano adesso vere scene3D isolate dello stesso CellVisual, con lo stesso genotipo, al posto delle sagome2D separate. Antialiasing2x.
- I GLB esistenti continuano a fornire la mesh membrana, i complessi e i moduli. La geometria RNA/DNA viene costruita a runtime. Questa revisione non afferma di aver rigenerato tutti i file Blender.

Verifiche: suite20 smoke test (campagna, fasi1/2, salvataggi, tutti16 loci e livelli, membrane, input e moduli), controlli statici e catture reali GL/Vulkan. Frame locali con prefisso `redesign-` sotto `build/previews`, inclusa galleria di8 fenotipi e schede delle figlie. Le immagini di riferimento non sono screenshot del gioco.

APK0.78 ARM64/OpenGL, pacchetto separato `org.origini.mobile.phase2078`, workflow con test, firma, verifica librerie16KiB e download pubblico. La valutazione estetica e delle prestazioni sul telefono richiede la prova dell'utente; nessun risultato fotorealistico dichiarato. La convenzione ludica della continuita del partner alla scissione resta quella discussa: non modificata in questa richiesta grafica.
