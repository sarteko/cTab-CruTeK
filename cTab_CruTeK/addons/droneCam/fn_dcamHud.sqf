/*
    crutek_fnc_dcamHud
    Aggiorna le due righe di testo sopra il feed.
*/

disableSerialization;
if (crutek_dcam_overlayOn isEqualTo "") exitWith {};

private _d = uiNamespace getVariable [crutek_dcam_overlayOn, displayNull];
if (isNull _d) exitWith {};

private _top = _d displayCtrl crutek_dcam_idcTop;
private _bot = _d displayCtrl crutek_dcam_idcBot;
if (isNull _top || {isNull _bot}) exitWith {};

private _uav = crutek_dcam_uav;
if (isNull _uav) exitWith {};

/*
    Bussola del telefono: il rilevamento di dove guarda CHI TIENE IN MANO il
    dispositivo, non di dove punta la sorgente.

    E la stessa cosa che leggi sulla barra della mappa di cTab, ed e il
    comportamento giusto per un oggetto che hai in mano: la bussola segue
    te, non il drone dall'altra parte della valle.

    Sta prima del ramo delle helmet cam apposta: quel ramo esce con exitWith
    e senza questo blocco qui sopra il rilevamento sparirebbe su OpCam.

    Tre cifre come su qualunque strumento vero: 007, 090, 315.
*/
private _brg = _d displayCtrl crutek_dcam_idcBrg;
if (!isNull _brg) then {
    private _v = getCameraViewDirection player;
    if (_v isEqualTo [0,0,0]) then { _v = vectorDir player };
    private _az = (_v select 0) atan2 (_v select 1);
    if (_az < 0) then { _az = _az + 360 };
    private _n = round _az;
    if (_n >= 360) then { _n = 0 };
    private _s = switch (true) do {
        case (_n < 10):  { format ["00%1", _n] };
        case (_n < 100): { format ["0%1", _n] };
        default { str _n };
    };

    /*
        Targhetta cucita sul numero, come quella del nome: la larghezza si
        misura davvero con getTextWidth passandogli lo stesso font e la
        stessa altezza con cui il testo viene disegnato. Il testo e centrato
        nel suo controllo, quindi la targhetta va centrata sullo stesso
        intervallo, non allineata a sinistra.

        Posizione riscritta a ogni giro e non solo al cambio del numero:
        passando dal telefonino al telefono aperto i controlli vengono
        ricreati da zero, e una posizione messa una volta sola resterebbe
        dov'era nata.
    */
    private _bg = _d displayCtrl crutek_dcam_idcBrgBg;
    if (!isNull _bg) then {
        private _alt = ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.75;
        private _mrg = _alt * crutek_dcam_namePad;
        private _lar = ((_s + toString [176]) getTextWidth ["PuristaBold", _alt]) max (_alt * 2);

        (ctrlPosition _brg) params ["_bx", "_by", "_bw", ""];
        _bg ctrlSetPosition [_bx + ((_bw - _lar - (_mrg * 2)) / 2), _by, _lar + (_mrg * 2), _alt * 1.35];
        _bg ctrlCommit 0;
        _bg ctrlShow true;
    };

    /*
        Il simbolo dei gradi si costruisce con toString invece di scriverlo
        nel sorgente: i file del mod sono ASCII puro, e infilare qui il primo
        byte fuori tabella significa dipendere da come l'editor salva il file
        e da come il gioco lo rilegge. 176 e il punto di codice del grado.
    */
    _brg ctrlSetStructuredText parseText format [
        "<t align='center' size='0.75' font='PuristaBold' color='#ffffff'>%1%2</t>",
        _s,
        toString [176]
    ];
};

if (crutek_dcam_kind isEqualTo "HCAM") exitWith {
    private _last = (count crutek_dcam_modesHcam) - 1;
    private _hm   = crutek_dcam_modesHcam select ((crutek_dcam_mode max 0) min _last);
    private _nome = [_uav] call crutek_fnc_dcamName;

    /*
        Targhetta scura dietro al nome, cucita sulla sua lunghezza.

        La larghezza del testo si misura davvero, con getTextWidth: gli si
        passa lo stesso font e la stessa altezza con cui viene disegnato, e
        risponde in unita di interfaccia. Prima la stimavo dal numero di
        lettere, ma PuristaMedium e proporzionale e dieci "i" non occupano
        come dieci "m": la targhetta finiva sempre lunga o corta. Cosi invece
        combacia con qualunque nome, di player o di IA.

        La targhetta parte esattamente dove parte il controllo del testo e si
        allunga solo verso destra. Prima la facevo cominciare un margine piu
        a sinistra per dare respiro alle lettere, ma il testo e gia a filo
        del bordo del video: quel margine finiva fuori dal riquadro e si
        vedeva sbordare a sinistra, soprattutto sul telefonino piccolo dove
        c'e poco spazio. Il respiro a sinistra lo da gia il margine interno
        del testo strutturato.

        crutek_dcam_namePad e quindi lo spazio che avanza a destra, misurato
        in altezze di carattere.

        La posizione si riscrive a ogni giro e non solo quando cambia il
        nome: passando dal telefonino al telefono a tutto schermo i controlli
        vengono ricreati da zero, e con la posizione messa una volta sola la
        targhetta restava dov'era nata, cioe in un angolo dello schermo.
    */
    private _modo = ["D-TV", "NV"] select (_hm isEqualTo "NVG");
    private _nam  = _d displayCtrl crutek_dcam_idcNam;

    /*
        Targhetta cucita sul nome e spinta a destra come lui: si parte dal
        bordo destro del controllo e si torna indietro della larghezza
        misurata, invece di partire da sinistra.
    */
    private _targa = _d displayCtrl crutek_dcam_idcName;
    if (!isNull _targa) then {
        private _alt = ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.65;
        private _mrg = _alt * crutek_dcam_namePad;
        private _lar = (_nome getTextWidth ["PuristaMedium", _alt]) max (_alt * 2);

        (ctrlPosition _nam) params ["_tx", "_ty", "_tw", ""];
        _targa ctrlSetPosition [_tx + _tw - _lar - (_mrg * 2), _ty, _lar + (_mrg * 2), _alt * 1.35];
        _targa ctrlCommit 0;
        _targa ctrlShow true;
    };

    /*
        In alto solo il nome: la sorgente la sai gia, e il modo di visione e
        finito in basso accanto alla distanza, dove non ruba spazio.
    */
    _top ctrlSetStructuredText parseText format [
        "<t size='0.7' color='#b6d3ad'>%1</t>",
        _modo
    ];
    _bot ctrlSetStructuredText parseText format [
        "<t size='0.65' color='#8fa389'>%1 m</t>",
        round (player distance _uav)
    ];
    if (!isNull _nam) then {
        _nam ctrlSetStructuredText parseText format [
            "<t align='right' size='0.65' color='%2'>%1</t>",
            _nome,
            crutek_dcam_nameColor
        ];
    };
};

// sui mezzi la targhetta non si usa: il nome sta sopra il video del drone,
// che e scuro, e li si legge benissimo
private _targaV = _d displayCtrl crutek_dcam_idcName;
if (!isNull _targaV) then { _targaV ctrlShow false };

private _fnc_short = {
    switch (_this) do {
        case "NVG":    { "NV" };
        case "THERM1": { "TH1" };
        case "THERM2": { "TH2" };
        default { "D-TV" };
    };
};

private _sel = crutek_dcam_modes select crutek_dcam_mode;
private _lbl = if (_sel isEqualTo "AUTO") then {
    format ["AUTO - %1", crutek_dcam_effective call _fnc_short]
} else {
    _sel call _fnc_short
};

/*
    L'etichetta "zoom libero / zoom operatore" era sempre a schermo e non
    diceva niente di utile: e sparita. Il ritaglio invece resta, ma solo
    quando c'e davvero, perche quello cambia l'inquadratura.
*/
private _src = "";
if (crutek_dcam_cropZoom > 1.01) then {
    _src = format ["  -  ritaglio %1x", (round (crutek_dcam_cropZoom * 10)) / 10];
};

/*
    L'ingrandimento si calcola rispetto all'ottica piu larga della torretta,
    non rispetto a un riferimento fisso: e cosi che lo calcola l'HUD del
    drone, quindi il numero sul telefono coincide con il suo CAM MAG.
*/
/*
    Ingrandimento riferito all'ottica piu larga del drone, letta dalla sua
    config: e lo stesso riferimento che usa il CAM MAG in torretta, quindi i
    due numeri devono coincidere. Se non coincidono, il riferimento da
    correggere e crutek_dcam_fovBase.
*/
private _wide = if (crutek_dcam_ladder isEqualTo []) then { 0.37 } else { crutek_dcam_ladder select 0 };
// la correzione di forma non e zoom: si toglie dal conto, cosi il numero
// resta confrontabile col CAM MAG della torretta
private _eff  = crutek_dcam_fovApplied / (crutek_dcam_fovAuto max 0.001);
private _mag  = (_wide / (_eff max 0.001)) * crutek_dcam_cropZoom;

/*
    In alto resta solo il filtro: il nome e sceso in basso perche in centro
    c'e il rilevamento, e con una sorgente dal nome lungo le due scritte si
    toccavano.
*/
_top ctrlSetStructuredText parseText format [
    "<t size='0.7' color='#b6d3ad'>%1</t>",
    _lbl
];

_bot ctrlSetStructuredText parseText format [
    "<t size='0.65' color='#8fa389'>alt %1 m  -  x%2%3</t>",
    round ((getPosATL _uav) select 2),
    (round (_mag * 10)) / 10,
    _src
];

private _namV = _d displayCtrl crutek_dcam_idcNam;
if (!isNull _namV) then {
    _namV ctrlSetStructuredText parseText format [
        "<t align='right' size='0.65' color='%2'>%1</t>",
        [_uav] call crutek_fnc_dcamName,
        crutek_dcam_nameColor
    ];
};
