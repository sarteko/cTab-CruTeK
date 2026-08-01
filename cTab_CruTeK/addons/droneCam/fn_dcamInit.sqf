/*
    crutek_fnc_dcamInit
    DroneCam on Galaxy - inizializzazione (postInit, ogni client)

    Mostra sullo schermo del Galaxy di cTab quello che inquadra la torretta
    di un drone, rispecchiando in tempo reale la vista di chi la comanda.

    Dipendenze: CBA_A3, ACE3, cTab. A3TI opzionale (senza, restano D-TV e NVG).
*/

if (!hasInterface) exitWith {};

/*
    Marcatore di versione. Serve a una cosa sola ma importante: dopo un
    repack, la prima riga [crutek_dcam] nel .rpt dice QUALE versione sta
    girando davvero. Se un errore continua a citare righe o nomi che nel
    file non esistono piu, e il PBO a contenere ancora la versione vecchia.
*/
crutek_dcam_version = "2026-08-01-c1";
diag_log format ["[crutek_dcam] versione %1", crutek_dcam_version];

if (!isNil "crutek_dcam_ready") exitWith {};
crutek_dcam_ready = true;

// ------------------------------------------------------------------
// CONFIGURAZIONE
// ------------------------------------------------------------------

crutek_dcam_item     = "ItemAndroid";
crutek_dcam_label    = localize "STR_crutek_dcam_menu_root";

// telecamera da casco: item che la abilita, etichetta ACE e campo visivo
crutek_dcam_labelHcam = localize "STR_crutek_dcam_menu_opcam";

// una voce sola per tutto cio che vola: droni, aerei, elicotteri
crutek_dcam_labelAir = localize "STR_crutek_dcam_menu_air";

// categorie e rami del menu
crutek_dcam_labelLand  = localize "STR_crutek_dcam_menu_land";
crutek_dcam_labelSea   = localize "STR_crutek_dcam_menu_sea";
crutek_dcam_labelPlane = localize "STR_crutek_dcam_menu_plane";
crutek_dcam_labelHeli  = localize "STR_crutek_dcam_menu_heli";
crutek_dcam_labelDrone = localize "STR_crutek_dcam_menu_drone";
crutek_dcam_labelTank  = localize "STR_crutek_dcam_menu_tank";
crutek_dcam_labelCar   = localize "STR_crutek_dcam_menu_car";
crutek_dcam_labelBoat  = localize "STR_crutek_dcam_menu_boat";
crutek_dcam_hcamFov  = 0.7;

/*
    Icone del menu ACE. Il percorso parte dal prefisso del PBO, quindi un
    file messo in cTab\img\ si scrive \ctab_camera\img\nome.paa
*/
/*
    Da qui in giu NON ci sono piu i filtri: fazioni, categorie, equipaggio,
    distanze e quota vivono nelle opzioni degli addon e li registra
    dcamSettings in preInit. Assegnarle anche qui le sovrascriverebbe,
    cancellando la scelta della missione.
*/

/*
    Icone. Ogni categoria ha la sua; tutto il resto sotto la radice usa
    camongalaxy, cosi rami e mezzi restano uniformi e si distingue a colpo
    d'occhio il livello a cui si sta navigando.
*/
crutek_dcam_icon      = "\ctab_camera\img\camongalaxy.paa";   // radice
crutek_dcam_iconSub   = "\ctab_camera\img\camongalaxy.paa";   // rami, mezzi e voci di servizio
crutek_dcam_iconHcam  = "\ctab_camera\img\ctab_helmetcam_ico.paa";  // OpCam
crutek_dcam_iconAir   = "\ctab_camera\img\iconair.paa";        // AirCam e aerei
crutek_dcam_iconHeli  = "\ctab_camera\img\iconheli.paa";       // elicotteri
crutek_dcam_iconLand  = "\ctab_camera\img\iconland.paa";       // LandCam e mezzi terrestri
crutek_dcam_iconSea   = "\ctab_camera\img\iconsea.paa";        // SeaCam e barche

/*
    Rami dei droni: stessa famiglia dell'ambiente ma icona propria, cosi si
    distinguono a colpo d'occhio dai mezzi con equipaggio.
*/
crutek_dcam_iconAirDrone  = "\ctab_camera\img\iconair_drone.paa";
crutek_dcam_iconLandDrone = "\ctab_camera\img\iconland_drone.paa";
crutek_dcam_iconSeaDrone  = "\ctab_camera\img\iconsea_drone.paa";
crutek_dcam_iconHide  = "\ctab_camera\img\camongalaxy.paa";
crutek_dcam_iconOff   = "\ctab_camera\img\camongalaxy.paa";
crutek_dcam_rt       = "rendertarget10";   // libero: cTab usa 8, 9, 12, 13

/*
    Lato in pixel della texture su cui viene disegnato il feed. cTab usa 512
    per le sue UAV cam, ed e da li che nasce la sgranatura quando il ritaglio
    digitale ingrandisce quei pixel.

    Valori sensati: 512, 1024, 2048. Raddoppiare il lato quadruplica i pixel
    da disegnare a ogni fotogramma, quindi si paga in prestazioni: se il
    telefono e sempre acceso mentre voli, 1024 e un buon compromesso, 2048
    solo se hai margine.

    Attenzione: questo NON e l'unico limite. La risoluzione con cui il gioco
    disegna dentro un render target la decide l'opzione video "PiP", ed e
    quella che va alzata per prima. Una texture grande alimentata da una PiP
    bassa resta sgranata uguale.
*/
crutek_dcam_rtSize   = 1024;

crutek_dcam_zoomSteps  = 7;

// distanza di resa del render target mentre il feed e acceso

// scrive nel .rpt ogni cambio di modo con i parametri applicati
crutek_dcam_debug = false;

/*
    Taratura fine della grandezza dell'immagine. Il FOV che arriva
    dall'operatore e riferito al suo schermo; il render target del telefono
    ha proporzioni diverse, quindi l'inquadratura puo risultare leggermente
    piu stretta o piu larga. 1 = nessuna correzione; sotto 1 stringe,
    sopra 1 allarga.
*/
crutek_dcam_fovScale = 1;

/*
    Forma del riquadro del feed.

    L'ottica del drone viene disegnata in torretta dentro un riquadro 4:3.
    Dando al feed la stessa forma, la stessa FOV produce la stessa
    inquadratura e gli oggetti hanno la stessa grandezza. Dandogli una forma
    diversa si ottiene l'effetto grandangolo, perche lo stesso valore di FOV
    su superfici di forma diversa copre angoli diversi.

      0      (default) riempi tutto lo schermo del telefono. Con la sincronia
             per rapporto di ingrandimento gli oggetti restano della stessa
             grandezza verticale che hanno nel FLIR: si vede solo piu campo
             ai lati, che e quello che il telefono deve fare
      1.333  incassa il feed in un 4:3 come il FLIR: inquadratura identica,
             ma con due bande ai lati

    Niente correzioni calcolate sul rapporto dello schermo: era un terzo
    rapporto in ballo e peggiorava le cose.
*/
crutek_dcam_frameAspect = 0;

/*
    Riferimento per riconvertire in FOV lo zoom pubblicato dall'operatore:
    fov = riferimento / zoom.

    NON e 0.75. Quello e il riferimento di CBA_fnc_getFov, cioe la vista a
    occhio nudo del giocatore, ma l'ottica di un drone parte gia molto piu
    stretta: la piu larga dello Yabhon vale circa 0.37. Usando 0.75 la FOV
    veniva due volte e mezza troppo larga, da cui l'effetto grandangolo.

    Il valore si ricava da una misura sola: metti il FLIR a un ingrandimento
    qualsiasi e leggi il numero sul telefono, poi

        riferimento = (fov reale del FLIR) x (numero letto sul telefono)

    Con FLIR a 0.5x su ottica larga 0.37 la sua fov vale 0.74, e col telefono
    che leggeva 0.4 viene 0.74 x 0.4 = 0.3.

    Se l'inquadratura resta piu larga di quella in torretta, abbassalo ancora;
    se diventa piu stretta, alzalo.
*/
crutek_dcam_fovBase = 0.3;

/*
    Riquadro del feed, espresso in frazioni del controllo mappa del telefono
    [x, y, larghezza, altezza]. I valori possono uscire da 0-1 per debordare.

    Nel config di cTab il vetro del telefono e alto 626 unita ma il controllo
    mappa e alto 566: le prime 60 sono riservate alla striscia di stato in
    alto (batteria, prua, ora, griglia). Appoggiandosi alla mappa, quella
    striscia resterebbe scoperta. Da qui l'altezza 626/566 e la partenza a
    -60/566, che portano il feed a coprire tutto il vetro.
    In larghezza la mappa deborda di 8 unita sul vetro (1098 contro 1090),
    quindi si rientra appena e si ricentra.

    [0, 0, 1, 1] = solo l'area mappa, con la striscia di stato in vista.
*/
crutek_dcam_frameRect = [0.0036, -0.106, 0.9927, 1.106];

/*
    Sensibilita del brandeggio a trascinamento. 1 = trascinando per tutta la
    larghezza del video ci si sposta di un campo visivo, quindi il gesto resta
    uguale a ogni ingrandimento. Alza per un brandeggio piu rapido.
*/
crutek_dcam_dragSens = 1;

/*
    Stabilizzazione del puntamento, in secondi di costante di tempo.
    ZERO significa nessun filtro: la camera segue la torretta esattamente.

    LASCIALO A ZERO se non hai un buon motivo. Il filtro non e un semplice
    smorzamento: stima anche la VELOCITA del brandeggio e la proietta in
    avanti, per non restare indietro quando l'operatore ruota. Basta che
    quella stima sbagli di poco e l'immagine scivola in quella direzione
    finche la correzione non la riacchiappa, poi ricomincia. Da fuori sembra
    un puntamento che vaga per conto suo.

    Ed e peggio a zoom alto, perche la costante di tempo cresce con
    l'ingrandimento: a x600 arriva al massimo di 1.2 secondi, quindi la
    deriva e lenta e ampia.

    Se un giorno lo riprovi, parti da 0.03 e guarda la mira mentre il drone
    e in movimento, non da fermo.
*/
crutek_dcam_smooth = 0;

/*
    Stato del mezzo usato per convertire il puntamento fra mondo e modello.

    true  = stato VISUALE, quello interpolato che finisce a schermo
    false = stato simulato, che avanza a passi fissi

    Il tremolio al massimo ingrandimento nasce quando la conversione usa uno
    stato e il disegno ne usa un altro: lo scarto e di frazioni di grado, e a
    due gradi di campo visivo si vede. Quale dei due sia quello giusto dipende
    da come il motore tratta una camera agganciata, e si scopre solo provando:
    metti il feed al massimo zoom su un drone in volo, guarda dieci secondi,
    poi cambia questo valore e riguarda. Vince quello piu fermo.
*/
crutek_dcam_aimVisual = true;

/*
    camSetFov accetta da 0.01 (piu stretto) a 8.5. Quello e il muro ottico:
    con un'ottica larga 0.37 il massimo ottico e circa 37x. Oltre, si passa
    al ritaglio digitale, che ingrandisce senza aggiungere dettaglio.
*/
crutek_dcam_fovMin = 0.0101;

// ingrandimento totale massimo raggiungibile, ottico piu ritaglio.
// ATTENZIONE: limita solo lo zoom EXTRA aggiunto con la rotella, non quello
// che arriva rispecchiando l'operatore. Se lui e in ULTN, il feed lo segue
// comunque e sotto il muro di camSetFov il ritaglio si accende da solo.
crutek_dcam_maxZoom = 100;

/*
    Ritaglio digitale, con un tetto.

    camSetFov non scende sotto 0.01: oltre quel muro l'unico modo di stringere
    ancora e ingrandire il quadro e tagliarne i bordi. Funziona, ma ha un
    difetto che cresce col fattore: la texture del feed e QUADRATA mentre
    l'immagine renderizzata ha la forma del riquadro del telefono, quindi il
    contenuto occupa solo una banda e il resto e vuoto. Ingrandendo la texture
    si ingrandiscono anche i vuoti, e la finestra visibile si sposta: da qui il
    soggetto decentrato e le fasce bianche ai bordi.

    A 1.5x lo scarto e impercettibile, a 7.5x l'immagine e a pezzi. Il tetto
    serve a stare nella parte buona della curva.

    crutek_dcam_cropMax:
      1    ritaglio spento, il feed si ferma al massimo ottico. Sempre
           centrato ma segue l'operatore solo per i primi scatti di zoom
      2    compromesso: qualche scatto in piu, decentramento appena visibile
      4+   segue l'operatore molto piu in la, ma l'inquadratura si sfalsa e
           compaiono le fasce bianche

    La cura vera sarebbe renderizzare in una texture con le stesse proporzioni
    del riquadro invece che quadrata. Finche non e cosi, questo e un dosaggio,
    non una soluzione.
*/
crutek_dcam_crop    = true;
crutek_dcam_cropMax = 1;

/*
    Portato a 1 il 29/07: con le ottiche vere dei mezzi l'ultimo scatto di
    certi droni scende sotto il muro di camSetFov, il ritaglio entrava in
    gioco al massimo consentito e le fasce bianche comparivano proprio li.
    A 1 il feed si ferma al massimo ottico e resta pulito.
*/

/*
    Scarto di ricentratura del puntamento, per tipo di drone, in gradi:
    ["classe", [azimut, elevazione], "altraClasse", [az, el], ...]
    Si trova in gioco con i tasti "DroneCam - ricentra ..." e la notifica
    scrive la riga gia pronta da incollare qui.
*/

// secondi di tolleranza prima di mollare il collegamento quando qualcosa
// non torna (drone sparito, controllo inventario che sbatte le palpebre)
crutek_dcam_grace = 3;


/*
    Le quattro posizioni del selettore sul Galaxy, in quest'ordine:
      AUTO   segue la termica che sta usando l'operatore della torretta
      NVG    visore notturno del gioco
      THERM1 termica 1 A3TI
      THERM2 termica 2 A3TI
*/
crutek_dcam_modes = ["AUTO", "NVG", "THERM1", "THERM2"];

// La cam operatore non ha termiche da mostrare: solo vista normale e notturno
crutek_dcam_modesHcam = ["DTV", "NVG"];

/*
    Tasti attivi anche col telefono aperto a tutto schermo. Servono perche in
    quella condizione il dialogo si prende gli eventi di tastiera e i keybind
    di CBA non arrivano. Tenere allineati ai predefiniti qui sotto.
    Formato: [DIK, maiusc, ctrl, alt, codice]
*/
crutek_dcam_dlgKeys = [
    [205, true, false, false, { [1]  call crutek_fnc_dcamCycle }],
    [203, true, false, false, { [-1] call crutek_fnc_dcamCycle }],
    [207, true, false, false, { call crutek_fnc_dcamToggle }],
    [211, true, false, false, { call crutek_fnc_dcamClose  }]
];


/*
    Modo base del render target, uno per voce del selettore.

    0 normale, 1 notturno, 2 termico: fin qui e quello che documenta il gioco,
    ed e il motivo per cui le due termiche uscivano identiche - passavo 2 a
    tutte e due, dopo aver verificato che il 7 non dava nessuna differenza.

    Sbagliavo, e la prova sta nel mod delle ottiche ReapIR, che gira sopra
    A3TI. La sua voce "polarity" cicla setPiPEffect su questi valori:

        [14, 14, 14, 7, 7, 7, 12]

    Quindi di indici ne esistono ben oltre il 2, e sono quelli che danno le
    polarita diverse. Se il mio vecchio controllo sul 7 non mostrava niente, o
    era fatto male o mancava qualcosa a monte.

    Qui THERM1 e THERM2 partono su 14 e 7. Quale dei due sia bianco caldo e
    quale nero caldo si vede in dieci secondi passando da una voce all'altra:
    se sono invertite basta scambiare i due numeri, e se una delle due non ti
    piace c'e anche il 12 da provare.

    Nota: la resa vera e propria - contrasto e luminosita del termico - la
    decide A3TI, che imposta i parametri globali del motore. Il render target
    li eredita da solo, senza che noi si debba fare niente.
*/
/*
    Indici di resa delle due termiche, FISSI nel codice.

    Erano due voci delle opzioni degli addon per poterli provare in partita.
    E stato un errore: i valori salvati in uno scenario vincono su quelli del
    codice, e un 20 rimasto li dentro faceva passare al motore un indice che
    non esiste - immagine diurna anche col selettore su TH1, senza nessun
    errore da nessuna parte.

    2 e 7 sono i valori documentati: termico e termico invertito, cioe bianco
    caldo e nero caldo. Non c'e motivo di renderli configurabili.
*/
crutek_dcam_thermA = 2;    // THERM1: bianco caldo
crutek_dcam_thermB = 7;    // THERM2: nero caldo

/*
    Luminosita e contrasto di riserva per la ricetta A3TI, usati solo se la
    sua funzione pubblica non risponde. Normalmente i valori arrivano da lui,
    cosi il feed segue le regolazioni del giocatore.
*/
// vero mentre A3TI tiene il mondo ridipinto: vedi dcamRefresh
crutek_dcam_paintNow = false;

/*
    Pesi con cui la correzione colore trasforma l'immagine in scala di grigi:
    [rosso, verde, blu, alfa].

    Contano perche adesso sappiamo con che colori A3TI dipinge gli oggetti
    caldi, e li ha dichiarati nei suoi materiali:

        TIRed.rvmat   (mezzi)   diffuse = 1.5, 0, 0     rosso puro, sovraesposto
        TIPink.rvmat  (teste)   ambient = 5, 0.56, 5    magenta, molto sovraesposto

    In tutti e due il VERDE e praticamente assente, mentre il terreno e la
    vegetazione ce l'hanno eccome. Da qui l'alternativa che vale la pena
    provare:

        [1, -1, 1, 0]

    somma rosso e blu e SOTTRAE il verde: i mezzi dipinti restano bianchi, le
    teste ancora di piu, il terreno scende a meta e la vegetazione va a nero.
    Separazione molto piu netta di una scala di grigi neutra.

    Di serie restano i pesi di A3TI, che sono quelli che usa lui a schermo:
    se il risultato ti convince gia cosi, non c'e motivo di toccarli.
*/
crutek_dcam_a3tiWeights = [0.33, 0.33, 0.33, 0];

crutek_dcam_a3tiBrt = 1;
crutek_dcam_a3tiCnt = 1;

crutek_dcam_baseFx = ["DTV", 0, "NVG", 1];

/*
    GRADAZIONI NON UTILIZZABILI, lasciate vuote di proposito.

    Il render target tiene un effetto alla volta e vince l'ultima chiamata:
    una correzione colore applicata dopo il modo base non ci si somma, lo
    SOSTITUISCE. Riempendo questi array si perde la termica invece di
    migliorarla, ed e da li che venivano lo schermo nero e le due termiche
    identiche. Vedi il commento in fn_dcamVision.
*/
crutek_dcam_grade    = [];
crutek_dcam_gradeInv = [];

/*
    RICETTA A3TI PIENA.

    A3TI non usa la termica del motore, la spegne: fabbrica la sua partendo
    dal canale diurno con tre ingredienti. Due sono modifiche al mondo (secondo
    sole e mezzi e uomini ridipinti di rosso) e si vedono anche nel render
    target; il terzo sono i pesi colore qui sotto, che trasformano il rosso in
    bianco caldo. Con tutti e tre insieme la resa e la sua.

    PREZZO: ridipingere il mondo e locale a questo client ma non alla sola
    camera, quindi mentre e attivo vedi mezzi e persone colorati anche a
    occhio nudo.

      "OFF"     (default) mai: si resta sulle termiche del gioco. E il valore
                giusto se A3TI non e caricata, e comunque tutto il ramo si
                disattiva da solo quando la mod non c'e
      "ALWAYS"  sempre, anche sul telefonino piccolo. E dove si
                guarda davvero, quindi e li che la ricetta deve valere.
                In cambio, ogni volta che sei su una termica vedi il mondo
                ridipinto anche a occhio nudo
      "DIALOG"  solo col telefono aperto a tutto schermo: il mondo si
                ridipinge solo mentre lo guardi, ma sul telefonino piccolo
                resti sulla termica del motore
*/
crutek_dcam_a3ti = "OFF";

/*
    Raggio in metri entro cui NON ridipingere, per non ritrovarti i compagni
    di squadra rossi davanti agli occhi. La tua squadra e protetta sempre,
    a qualunque distanza.

    0 disattiva la protezione: viene ridipinto tutto, come fa A3TI di suo.

    E una fotografia scattata all'accensione della termica: chi era lontano e
    poi si avvicina resta rosso finche non cambi modo.
*/
crutek_dcam_paintKeep = 250;

// numeri presi da fn_ppEffects.sqf di A3TI, caso 0. I pesi sommano a 0.66
crutek_dcam_a3tiWhot = [3, 1, 1.16, 0.62, 0.04, [0,0,0,0], [1,1,1,0], [3.84,-0.46,-2.72,-0.06]];
// il nero caldo di A3TI aggiunge un ColorInversion, che il render target non
// ha: si approssima negando i pesi e riportando in scala con l'offset
crutek_dcam_a3tiBhot = [3, 1, 1.16, 0.62, 0.96, [0,0,0,0], [1,1,1,0], [-3.84,0.46,2.72,0.06]];


// ------------------------------------------------------------------
// STATO
// ------------------------------------------------------------------

crutek_dcam_active   = false;
crutek_dcam_cam      = objNull;
crutek_dcam_uav      = objNull;
crutek_dcam_posMem   = "";
crutek_dcam_aim      = "";
crutek_dcam_dirMem   = "";
crutek_dcam_mode      = 0;
crutek_dcam_effective = "";
crutek_dcam_hasOp     = false;
crutek_dcam_ladder   = [];
crutek_dcam_fov      = 0.7;
crutek_dcam_mods     = [false, false, false];
crutek_dcam_hidden    = false;
crutek_dcam_lastDir    = [];
crutek_dcam_lastRate   = [0, 0, 0];
crutek_dcam_fovApplied = 0.7;
crutek_dcam_fovAuto    = 1;
crutek_dcam_cropZoom   = 1;
crutek_dcam_picBox     = [0, 0];
crutek_dcam_dragging   = false;
crutek_dcam_dragLast   = [0, 0];
crutek_dcam_dragTick   = 0;
crutek_dcam_locked     = false;
crutek_dcam_aimAz      = 0;
crutek_dcam_aimEl      = 0;
crutek_dcam_picRect    = [0, 0, 0, 0];
crutek_dcam_kind       = "DRONE";
crutek_dcam_hcamTgt    = objNull;
crutek_dcam_worldOn    = false;
crutek_dcam_fullNow    = false;
crutek_dcam_graceT   = -1;
crutek_dcam_overlayOn = "";
crutek_dcam_ehKey    = -1;
crutek_dcam_ehKeyUp  = -1;
crutek_dcam_ehClick  = -1;
crutek_dcam_ehUp     = -1;
crutek_dcam_ehWheel  = -1;
// filtro anti doppione della rotella: vedi dcamWheel
crutek_dcam_wheelTick = 0;
// distanza visiva: valori da rimettere alla chiusura, -1 = non toccata
crutek_dcam_prevVD    = -1;
crutek_dcam_prevOVD   = -1;
crutek_dcam_ovdRatio  = 0;
crutek_dcam_vdTick    = 0;

/*
    ---- distanza visiva col feed acceso -----------------------------

    Applica la visiva minima chiesta dalle impostazioni, se l'abbiamo gia
    alzata all'apertura del feed.

    Due cose imparate leggendo il limitatore di ACE.

    ACE non applica mai un valore secco: fa setViewDistance del valore scelto
    LIMITATO da ace_viewdistance_limitViewDistance, che nel suo pannello e la
    voce "Limite Distanza Visiva". Chiedere di piu non serve a niente, quindi
    ci limitiamo da soli invece di farci correggere al primo cambio di stato.

    E subito dopo fa setObjectViewDistance in proporzione alla visiva. Se
    alzassimo solo la visiva, il terreno si pulirebbe ma gli oggetti
    resterebbero disegnati fin dove arrivavano prima: cielo terso e hangar
    che non ci sono. Quindi si conserva la proporzione che c'era al momento
    dell'apertura, qualunque l'avesse decisa.
*/
crutek_dcam_applyVD = {
    if (crutek_dcam_prevVD <= 0) exitWith {};

    private _tetto = missionNamespace getVariable ["ace_viewdistance_limitViewDistance", 12000];
    private _vuole = crutek_dcam_viewDist min _tetto;
    if (viewDistance >= _vuole) exitWith {};

    setViewDistance _vuole;
    if (crutek_dcam_ovdRatio > 0) then {
        setObjectViewDistance (crutek_dcam_ovdRatio * _vuole);
    };
};

/*
    Gli stessi eventi su cui ACE riapplica la sua distanza: cambio di mezzo e
    presa di controllo di un drone. Ci si accoda con un fotogramma di ritardo
    per arrivare dopo di lui, altrimenti scrive lui per ultimo e vince il suo
    valore. Il controllo periodico in dcamFrame resta come rete, per i casi
    che questi due eventi non coprono.
*/
["vehicle", {
    [{ call crutek_dcam_applyVD }] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addPlayerEventHandler;

["ACE_controlledUAV", {
    [{ call crutek_dcam_applyVD }] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addEventHandler;
crutek_dcam_ehDlg    = [];
crutek_dcam_hudTick  = 0;
crutek_dcam_hasA3TI  = !isNil "A3TI_fnc_getA3TIVision";

// IDC dei controlli che creo al volo sullo schermo del telefono
crutek_dcam_idcGrp = 91000;
crutek_dcam_idcPic = 91001;
crutek_dcam_idcTop = 91002;
crutek_dcam_idcBot = 91003;

/*
    Le due bande sono a tre scomparti: fondo piu tre testi allineati a
    sinistra, al centro e a destra. Un testo strutturato ha un allineamento
    solo, quindi servono tre controlli per riga.
*/
crutek_dcam_idcTopL = 91005;
crutek_dcam_idcTopC = 91006;
crutek_dcam_idcTopR = 91007;
crutek_dcam_idcBotL = 91008;
crutek_dcam_idcBotC = 91009;
crutek_dcam_idcBotR = 91010;

/*
    Fondo delle bande: nero al 45 per cento, lo stesso della vecchia
    targhetta del nome.
*/
crutek_dcam_bandColor = [0, 0, 0, 0.45];

/*
    Colore delle scritte. Bianche col contorno nero su tutte le viste - il
    contorno e cio che le tiene leggibili sul cielo chiaro senza dover
    scurire la banda - e verdi solo in notturno, dove il bianco spara e il
    verde e la convenzione.
*/
crutek_dcam_hudColor = "#ffffff";
crutek_dcam_hudColorNV = "#a6ff00";
/*
    Lettere della rosa dei venti, otto settori da 45 gradi. Uguali nelle due
    lingue - N, NE, E, SE, S, SW, W, NW - perche sulla strumentazione la
    dicitura inglese e quella che si legge ovunque. Restano nello stringtable
    per poterle cambiare senza toccare il codice.
*/
crutek_dcam_compass = (localize "STR_crutek_dcam_hud_compass") splitString ",";

// ------------------------------------------------------------------
// VOCE MENU ACE
// ------------------------------------------------------------------

/*
    MENU ACE, ad albero:

        Cam on Galaxy
          |- OpCam     telecamere da casco
          |- AircraftCam  |- Plane  |- Heli  |- Drone
          |- VehiclesCam  |- Tank   |- Car   |- Drone
          |- BoatsCam     |- Boat   |- Drone
          |- Nascondi feed      (solo a feed acceso)
          |- Scollega           (solo a feed acceso)

    Categorie e rami vuoti non vengono mostrati affatto.

    I due sottomenu vengono costruiti per intero qui dentro, come figli
    statici del ramo: e piu solido che annidare piu livelli di generazione
    dinamica, e la lista si rigenera comunque a ogni apertura del menu.
*/

[] spawn {
    waitUntil { sleep 0.5; !isNil "ace_interact_menu_fnc_createAction" };

    private _fnc_children = {
        private _actions = [];

        // ---- OpCam: telecamere da casco --------------------------
        private _opFigli = [];
        {
            private _u   = _x;
            private _act = [
                format ["crutek_opcam_%1", netId _u],
                format ["%1  -  %2 m", [_u] call crutek_fnc_dcamName, round (player distance _u)],
                crutek_dcam_iconHcam,
                { [_this select 2, "HCAM"] call crutek_fnc_dcamOpen },
                { true },
                {},
                _u
            ] call ace_interact_menu_fnc_createAction;
            _opFigli pushBack [_act, [], _u];
        } forEach (if (crutek_dcam_catOpCam) then { call crutek_fnc_dcamHcams } else { [] });

        private _opCam = [
            "crutek_viewcam_op",
            crutek_dcam_labelHcam,
            crutek_dcam_iconHcam,
            {},
            { true }
        ] call ace_interact_menu_fnc_createAction;
        if (crutek_dcam_catOpCam) then { _actions pushBack [_opCam, _opFigli, objNull] };

        /*
            ---- i mezzi, divisi per ambiente e categoria ----------

            Chi e un drone si decide con allUnitsUAV, non con isKindOf "UAV":
            non tutti i droni ereditano da quella classe, i modded quasi mai,
            e finivano nel raccoglitore. allUnitsUAV elenca i mezzi senza
            equipaggio direttamente, ed e lo stesso test che usa cTab.

            I droni stanno in un ramo loro in ogni ambiente: sono gli unici su
            cui si puo brandeggiare la torretta col tasto destro.
        */
        private _tutti   = call crutek_fnc_dcamList;
        private _senzaEq = allUnitsUAV;

        /*
            Riconoscere un drone: nessuno dei due test da solo basta.
            allUnitsUAV non elenca tutti i droni modded, e isKindOf "UAV" non
            vale per quelli che non ereditano da quella classe. Messi in OR
            ne prendono molti di piu, ed e per questo che finivano fra gli
            elicotteri invece che nel loro ramo.
        */
        private _fnc_drone = {
            (_this in _senzaEq) || {_this isKindOf "UAV"}
        };

        private _aria  = if (crutek_dcam_catAir)  then { _tutti select { _x isKindOf "Air" } }  else { [] };
        private _mare  = if (crutek_dcam_catSea)  then { _tutti select { _x isKindOf "Ship" } } else { [] };
        private _terra = if (crutek_dcam_catLand) then { _tutti - (_tutti select { _x isKindOf "Air" }) - (_tutti select { _x isKindOf "Ship" }) } else { [] };

        private _fnc_ramo = {
            params ["_id", "_titolo", "_lista", ["_icona", ""]];
            if (_lista isEqualTo []) exitWith { [] };

            private _figli = [];
            {
                private _v   = _x;
                private _act = [
                    format ["crutek_cam_%1", netId _v],
                    format ["%1  -  %2 m", [_v] call crutek_fnc_dcamName, round (player distance _v)],
                    _icona,
                    { [_this select 2, "VEH"] call crutek_fnc_dcamOpen },
                    { true },
                    {},
                    _v
                ] call ace_interact_menu_fnc_createAction;
                _figli pushBack [_act, [], _v];
            } forEach _lista;

            private _ramo = [
                _id,
                format ["%1  (%2)", _titolo, count _lista],
                _icona,
                {},
                { true }
            ] call ace_interact_menu_fnc_createAction;

            [[_ramo, _figli, objNull]]
        };

        private _fnc_categoria = {
            params ["_id", "_titolo", "_lista", "_rami", ["_icona", ""]];
            if (_lista isEqualTo []) exitWith {};

            private _figli = [];
            { _figli append _x } forEach _rami;

            private _cat = [
                _id,
                format ["%1  (%2)", _titolo, count _lista],
                _icona,
                {},
                { true }
            ] call ace_interact_menu_fnc_createAction;

            _actions pushBack [_cat, _figli, objNull];
        };

        // ---- AirCam: Plane, Heli, Drone ------------------------
        [
            "crutek_viewcam_air", crutek_dcam_labelAir, _aria,
            [
                (["crutek_air_plane", crutek_dcam_labelPlane,
                    _aria select { !(_x call _fnc_drone) && {!(_x isKindOf "Helicopter")} },
                    crutek_dcam_iconAir] call _fnc_ramo),
                (["crutek_air_heli", crutek_dcam_labelHeli,
                    _aria select { !(_x call _fnc_drone) && {_x isKindOf "Helicopter"} },
                    crutek_dcam_iconHeli] call _fnc_ramo),
                (["crutek_air_drone", crutek_dcam_labelDrone,
                    _aria select { _x call _fnc_drone },
                    crutek_dcam_iconAirDrone] call _fnc_ramo)
            ],
            crutek_dcam_iconAir
        ] call _fnc_categoria;

        // ---- LandCam: Tank, Car, Drone -------------------------
        [
            "crutek_viewcam_land", crutek_dcam_labelLand, _terra,
            [
                (["crutek_land_tank", crutek_dcam_labelTank,
                    _terra select { !(_x call _fnc_drone) && {_x isKindOf "Tank"} },
                    crutek_dcam_iconLand] call _fnc_ramo),
                (["crutek_land_car", crutek_dcam_labelCar,
                    _terra select { !(_x call _fnc_drone) && {!(_x isKindOf "Tank")} },
                    crutek_dcam_iconLand] call _fnc_ramo),
                (["crutek_land_drone", crutek_dcam_labelDrone,
                    _terra select { _x call _fnc_drone },
                    crutek_dcam_iconLandDrone] call _fnc_ramo)
            ],
            crutek_dcam_iconLand
        ] call _fnc_categoria;

        // ---- SeaCam: Boat, Drone -------------------------------
        [
            "crutek_viewcam_sea", crutek_dcam_labelSea, _mare,
            [
                (["crutek_sea_boat", crutek_dcam_labelBoat,
                    _mare select { !(_x call _fnc_drone) },
                    crutek_dcam_iconSea] call _fnc_ramo),
                (["crutek_sea_drone", crutek_dcam_labelDrone,
                    _mare select { _x call _fnc_drone },
                    crutek_dcam_iconSeaDrone] call _fnc_ramo)
            ],
            crutek_dcam_iconSea
        ] call _fnc_categoria;

        // ---- nascondi e rimostra, solo a feed acceso --------------
        if (crutek_dcam_active) then {
            private _tog = [
                "crutek_dcam_toggle",
                [localize "STR_crutek_dcam_menu_hide", localize "STR_crutek_dcam_menu_show"] select crutek_dcam_hidden,
                crutek_dcam_iconHide,
                { call crutek_fnc_dcamToggle },
                { true }
            ] call ace_interact_menu_fnc_createAction;
            _actions pushBack [_tog, [], objNull];
        };

        _actions
    };

    private _root = [
        "crutek_camsamsung_root",
        crutek_dcam_label,
        crutek_dcam_icon,
        {},
        { [ACE_player] call crutek_fnc_dcamHasItem },
        _fnc_children
    ] call ace_interact_menu_fnc_createAction;

    ["CAManBase", 1, ["ACE_SelfActions"], _root, true] call ace_interact_menu_fnc_addActionToClass;
};

// ------------------------------------------------------------------
// TASTI (sezione cTab del menu comandi di CBA)
// ------------------------------------------------------------------
// Ctrl+Maiusc+rotella zooma, Ctrl+Alt+rotella cambia filtro, Ctrl+Maiusc+clic
// rotella nasconde il video: quelli funzionano sempre. Questi sono in piu, e
// da qui li riassegni come vuoi.

/*
    ATTENZIONE AL PREFISSO DEI NOMI.

    CBA lega i tasti al nome interno dell'azione e li scrive nel profilo alla
    prima registrazione. Da quel momento il predefinito nel codice non conta
    piu nulla: vince sempre quello salvato. E la stessa proprieta che fa
    sopravvivere le riassegnazioni del giocatore, ma finche i nomi restano
    uguali blocca anche le correzioni ai predefiniti.

    Per questo il prefisso porta una versione: cambiandola, per CBA sono
    azioni nuove e ripartono dal predefinito scritto qui. Va toccata SOLO
    quando si cambiano i predefiniti, e sapendo che azzera le riassegnazioni
    fatte dai giocatori.

    overwrite resta false: la scelta del giocatore vince sempre su questi.
*/
#define CRUTEK_DCAM_KEYVER "dcam2"
private _fnc_bind = {
    params ["_name", "_title", "_tip", "_code", "_key", "_mods"];
    [
        "cTab Camera",
        format ["%1_%2", CRUTEK_DCAM_KEYVER, _name],
        [format ["DroneCam - %1", _title], _tip],
        _code,
        "",
        [_key, _mods],
        false
    ] call CBA_fnc_addKeybind;
};

/*
    Predefiniti allineati alla rotella:
      Maiusc+frecce sx/dx   filtri
      Maiusc+Fine           nascondi  (come Maiusc+clic rotella)
      Maiusc+Canc           scollega
    Ordine dei modificatori: [maiusc, ctrl, alt]

    Ogni handler restituisce "gestito" SOLO a feed acceso: cosi a feed spento
    il tasto passa oltre e non ruba combinazioni ad altro.
*/



["modeNext", localize "STR_crutek_dcam_key_modeNext", localize "STR_crutek_dcam_key_modeNext_t",
    { if (!crutek_dcam_active) exitWith { false }; [1] call crutek_fnc_dcamCycle; true },
    205, [true, false, false]] call _fnc_bind;

["modePrev", localize "STR_crutek_dcam_key_modePrev", localize "STR_crutek_dcam_key_modePrev_t",
    { if (!crutek_dcam_active) exitWith { false }; [-1] call crutek_fnc_dcamCycle; true },
    203, [true, false, false]] call _fnc_bind;

["hide", localize "STR_crutek_dcam_key_hide", localize "STR_crutek_dcam_key_hide_t",
    { if (!crutek_dcam_active) exitWith { false }; call crutek_fnc_dcamToggle; true },
    207, [true, false, false]] call _fnc_bind;

["off", localize "STR_crutek_dcam_key_off", localize "STR_crutek_dcam_key_off_t",
    { if (!crutek_dcam_active) exitWith { false }; call crutek_fnc_dcamClose; true },
    211, [true, false, false]] call _fnc_bind;

/*
    Cambio operatore. Il comando vero e Maiusc + rotella, che si gestisce nel
    codice perche la rotella non e assegnabile da CBA. Queste due voci sono
    qui perche compaiano fra i comandi del mod e chi vuole possa mettercele
    su un tasto: di serie non hanno nessuna combinazione.
*/
["opNext", localize "STR_crutek_dcam_key_opNext", localize "STR_crutek_dcam_key_opNext_t",
    { if (!crutek_dcam_active) exitWith { false }; [1] call crutek_fnc_dcamNext; true },
    0, [false, false, false]] call _fnc_bind;

["opPrev", localize "STR_crutek_dcam_key_opPrev", localize "STR_crutek_dcam_key_opPrev_t",
    { if (!crutek_dcam_active) exitWith { false }; [-1] call crutek_fnc_dcamNext; true },
    0, [false, false, false]] call _fnc_bind;

/*
    Il brandeggio ha bisogno di premi-e-tieni, quindi si registra anche il
    codice di rilascio. Nessun tasto predefinito: il tasto destro del mouse
    sul video funziona sempre, questo e per chi lo vuole altrove.
*/
[
    "cTab Camera",
    CRUTEK_DCAM_KEYVER + "_drag",
    [localize "STR_crutek_dcam_key_drag", localize "STR_crutek_dcam_key_drag_t"],
    { if (!crutek_dcam_active) exitWith { false }; ["START"] call crutek_fnc_dcamDrag },
    { if (!crutek_dcam_dragging) exitWith { false }; ["STOP"] call crutek_fnc_dcamDrag },
    [0, [false, false, false]],
    false
] call CBA_fnc_addKeybind;





// ------------------------------------------------------------------
// PUBLISHER LATO OPERATORE
// ------------------------------------------------------------------

[{ call crutek_fnc_dcamPublish }, 0.15, []] call CBA_fnc_addPerFrameHandler;

["unit", { if (crutek_dcam_active) then { call crutek_fnc_dcamClose }; }] call CBA_fnc_addPlayerEventHandler;
