# cTab CruTeK

![cTab CruTeK](img/cover.jpeg)

Versione modificata di **cTab** per ARMA 3. Aggiunge *Cam on Galaxy*: il feed video di caschi, torrette, mezzi e droni riprodotto **dentro lo schermo del Samsung Galaxy**, in render-to-texture, sia sul telefono aperto sia su quello piccolo sempre a schermo.

Non è un mod a parte: **sostituisce cTab**. Non vanno caricati insieme.

---

## Indice

- [Cosa aggiunge](#cosa-aggiunge)
- [Requisiti](#requisiti)
- [Installazione](#installazione)
- [Come si usa](#come-si-usa)
  - [Cosa serve avere addosso](#cosa-serve-avere-addosso)
  - [Il menu](#il-menu)
  - [Comandi](#comandi)
- [Opzioni](#opzioni)
  - [cTab-Cam on Galaxy](#ctab-cam-on-galaxy)
  - [cTab-Drones](#ctab-drones)
  - [cTab-HelmetCam](#ctab-helmetcam)
- [Diagnostica](#diagnostica)
- [Note tecniche](#note-tecniche)
- [Crediti](#crediti)

---

## Cosa aggiunge

Rispetto a cTab originale:

- **Cam on Galaxy** — un menu ACE ad albero da cui colleghi il Galaxy a una sorgente video e la guardi sullo schermo del telefono
- **Sorgenti**: helmet cam degli operatori, torrette di aerei, elicotteri, droni, carri, ruotati e mezzi navali
- **Brandeggio della torretta** dei droni senza operatore, direttamente dal video
- **Zoom a scatti** ripresi dai pod di puntamento reali
- **Permessi per fazione, categoria di mezzo e tipo di occupante**, tutti dalle opzioni degli addon, quindi impostabili per missione
- Le finestrelle di serie di cTab (UAV e helmet cam) passano da render target 512 a **1024**

Il resto di cTab — tablet, mappa, marker, MicroDAGR — resta quello che conosci.

![Feed di un drone sul Galaxy](img/sc1.jpeg)

*Il feed di un drone dentro lo schermo del telefono, con sorgente, quota, zoom e modalità in sovrimpressione.*

---

## Requisiti

| Mod | Necessità |
|---|---|
| **CBA_A3** | obbligatorio |
| **ACE3** | obbligatorio, il menu è un menu di auto-interazione ACE |

Il **PiP** va abilitato nelle opzioni video di ogni giocatore: è quello che disegna il feed dentro lo schermo del telefono. Con il PiP spento lo schermo resta nero.

> Non caricare cTab originale insieme a questo. Il prefisso interno è rimasto `cTab` e le classi hanno gli stessi nomi: convivono male.

---

## Installazione

Come qualunque mod: cartella `@cTab_CruTeK` con dentro `addons\cTab_CruTeK.pbo`, e la spunti nel launcher al posto di cTab.

Gli oggetti restano quelli di sempre — `ItemcTab`, `ItemAndroid`, `ItemMicroDAGR`, `ItemcTabHCam` — quindi le missioni scritte per cTab continuano a funzionare senza toccare niente.

---

## Come si usa

### Cosa serve avere addosso

**Per guardare**: il **Samsung Galaxy** (`ItemAndroid`) in inventario. È lui lo schermo su cui esce il feed.

**Per essere guardati**:

| Sorgente | Cosa serve |
|---|---|
| Helmet cam | l'oggetto **`ItemcTabHCam`** addosso all'operatore |
| Torrette e droni | niente di particolare: conta il mezzo, la sua fazione e chi c'è a bordo |

La classe dell'oggetto helmet cam è configurabile dalle opzioni, se usi un item diverso.

![Helmet cam di notte](img/sc3.jpeg)

*OpCam su un operatore, con visore notturno: in alto il nome di chi porta la cam, la modalità e la distanza.*

### Il menu

Menu di **auto-interazione ACE** (`Ctrl` + tasto di interazione), voce **Cam on Galaxy**. Compare solo se hai il Galaxy addosso.

```
Cam on Galaxy
├── OpCam                 helmet cam degli operatori
├── AircraftCam
│   ├── Drone
│   ├── Plane
│   └── Heli
├── VehiclesCam
│   ├── Drone
│   ├── Tank
│   └── Car
├── BoatsCam
│   ├── Drone
│   └── Boat
├── Hide feed / Show feed again
├── Disconnect
└── Diagnostics and version
```

I rami e le categorie vuote non vengono mostrati: se in giro non ci sono elicotteri, il ramo Heli non compare. In lista finiscono solo i mezzi ammessi dalle opzioni.

I droni hanno una voce propria dentro ogni ambiente, e non è un vezzo: sono gli unici su cui puoi brandeggiare la torretta.

![Menu di auto-interazione ACE](img/sc2.jpeg)

*Accanto a ogni ramo c'è il numero di sorgenti disponibili in quel momento: sai se vale la pena aprirlo prima di aprirlo.*

### Comandi

Sempre attivi, non serve assegnarli:

| Comando | Effetto |
|---|---|
| Tasto destro tenuto premuto sul video | brandeggia la torretta — solo droni senza operatore, solo col telefono aperto |
| `Maiusc` + rotella | operatore successivo/precedente — solo su OpCam |
| `Maiusc` + clic rotella | nasconde il video e torna alla mappa |

Assegnati di serie, riassegnabili dalla sezione **cTab CruTeK** dei comandi CBA:

| Tasto | Effetto |
|---|---|
| `Maiusc` + freccia destra / sinistra | filtro visione successivo / precedente |
| `Maiusc` + `Fine` | nascondi il video |
| `Maiusc` + `Canc` | scollega |

Registrati ma **senza tasto predefinito**, se li vuoi te li assegni tu: operatore successivo, operatore precedente, brandeggio.

Tutti questi tasti rispondono **solo a feed acceso**. A feed spento la combinazione passa oltre e non ruba niente ad altri mod.

---

## Opzioni

Tutto sta nelle **opzioni degli addon**, in tre sezioni separate. Essendo impostazioni di missione, le imposti una volta per scenario dall'editor.

### cTab-Cam on Galaxy

Vale per i mezzi con equipaggio.

**Fazioni osservabili** — la propria, blufor, opfor, indipendenti, civili. Di serie: propria, blufor e civili.

**Categorie di mezzi** — aria, terra, mare. Tutte accese.

**Chi deve essere a bordo** — quattro valori, di serie il primo:

| Valore | Significato |
|---|---|
| player o IA | basta che ci sia qualcuno |
| solo player | serve un giocatore |
| solo IA | serve un'IA |
| anche vuoti | nessun controllo |

> "Anche vuoti" non è il default per un motivo: la torretta di un mezzo vuoto sta ferma dove l'hanno lasciata, e il feed guarda dove capita.

**Limiti di gioco** — distanza massima dalla sorgente (4000 m), quota minima, e distanza visiva minima mentre il feed è acceso.

> La distanza visiva è **una sola** per tutto il rendering: alzandola per il feed alzi anche la tua vista reale finché il feed resta aperto. Di serie è a `0`, cioè il mod non la tocca. Se ti serve, la strada pulita è alzare il valore di ACE per chi fa da operatore droni.

### cTab-Drones

Sezione a parte, perché sui droni il ragionamento sull'equipaggio non ha senso: **chi comanda un drone sta al terminale, non a bordo**. L'equipaggio di un drone è sempre IA, anche mentre lo piloti tu.

- interruttore generale della categoria droni
- fazioni proprie, indipendenti da quelle dei mezzi
- **chi comanda il drone**: player o IA, solo player, solo IA — legge chi è collegato al terminale
- distanza massima propria (6000 m)
- brandeggio della torretta abilitato o no

### cTab-HelmetCam

- interruttore generale
- **classe dell'oggetto** richiesto, di serie `ItemcTabHCam`
- distanza massima (2000 m)
- **chi porta la cam**: player o IA, solo player, solo IA
- fazioni proprie

---

## Diagnostica

All'avvio, nel `.rpt`:

```
[crutek_dcam] versione 2026-07-29-r16
[crutek_dcam] impostazioni registrate: cTab-Cam on Galaxy e cTab-HelmetCam
```

Se la prima riga non c'è, il modulo non è partito. In gioco, la voce **Diagnostics and version** in fondo al menu ti dice a schermo versione e stato corrente.

### Se qualcosa non va

| Sintomo | Da guardare |
|---|---|
| il menu Cam on Galaxy non compare | hai il Galaxy (`ItemAndroid`) addosso? ACE è caricato? |
| schermo del telefono nero | PiP abilitato nelle opzioni video? |
| un mezzo non compare in lista | fazione abilitata? categoria accesa? rientra nella distanza massima? soddisfa la regola su chi deve essere a bordo? |
| un operatore non compare | ha `ItemcTabHCam`? la sua fazione è fra quelle osservabili in cTab-HelmetCam? |
| il tasto destro non brandeggia | funziona solo sui droni **senza operatore** e col telefono aperto; e il brandeggio va abilitato in cTab-Drones |
| immagine sgranata | è l'impostazione PiP delle opzioni video, ed è per giocatore |

---

## Note tecniche

**Il feed riempie tutto lo schermo del telefono.** Non ci sono bande laterali, anche a costo di inquadrare più largo di quanto farebbe l'ottica vera.

**Lo zoom dell'operatore è il fondo scala.** Collegandoti parti da dove sta guardando lui, e da lì puoi solo stringere: non puoi allargare oltre il suo campo visivo. Gli scatti sono quelli dei pod di puntamento reali.

**Termiche vanilla.** Il mod non dipende da A3TI e non ne riproduce la resa: quella lavora con effetti disegnati sullo schermo del giocatore, e uno schermo non entra in un render target.

**L'arsenale scollega il feed.** Sia quello di ACE sia quello vanilla: aprire l'arsenale mentre un feed è acceso lo stacca invece di lasciarlo appeso.

**I tasti CBA e il profilo.** CBA lega i tasti al nome interno dell'azione e li scrive nel profilo alla prima registrazione: da quel momento il predefinito nel codice non conta più, vince quello salvato. È la stessa proprietà che fa sopravvivere le riassegnazioni del giocatore. Per questo il prefisso dei nomi porta una versione: cambiandola, per CBA sono azioni nuove e ripartono dal predefinito. Va toccata solo cambiando i predefiniti, sapendo che azzera le riassegnazioni fatte dai giocatori.

---

## Crediti

Basato su **cTab** di Gundy e collaboratori. Le modifiche di questa versione sono di **CruTeK / ArTeK**.

Segnalazioni e idee sono benvenute: [github.com/sarteko](https://github.com/sarteko)
