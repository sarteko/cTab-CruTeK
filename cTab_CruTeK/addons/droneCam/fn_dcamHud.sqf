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
    private _targa = _d displayCtrl crutek_dcam_idcName;
    if (!isNull _targa) then {
        private _alt = ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.7;
        private _mrg = _alt * crutek_dcam_namePad;
        private _lar = (_nome getTextWidth ["PuristaMedium", _alt]) max (_alt * 2);

        (ctrlPosition _top) params ["_tx", "_ty", "", ""];
        _targa ctrlSetPosition [_tx, _ty, _lar + (_mrg * 2), _alt * 1.35];
        _targa ctrlCommit 0;
        _targa ctrlShow true;
    };

    /*
        In alto solo il nome: la sorgente la sai gia, e il modo di visione e
        finito in basso accanto alla distanza, dove non ruba spazio.
    */
    _top ctrlSetStructuredText parseText format [
        "<t size='0.7' color='%2'>%1</t>",
        _nome,
        crutek_dcam_nameColor
    ];
    _bot ctrlSetStructuredText parseText format [
        "<t size='0.65' color='#8fa389'>%1 m  -  %2</t>",
        round (player distance _uav),
        ["D-TV", "NV"] select (_hm isEqualTo "NVG")
    ];
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

private _src = if (crutek_dcam_hasOp) then { localize "STR_crutek_dcam_hud_opZoom" } else { localize "STR_crutek_dcam_hud_freeZoom" };
if (crutek_dcam_cropZoom > 1.01) then {
    _src = format ["%1 - ritaglio %2x", _src, (round (crutek_dcam_cropZoom * 10)) / 10];
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

_top ctrlSetStructuredText parseText format [
    "<t size='0.7' color='#b6d3ad'>%1  -  %2</t>",
    [_uav] call crutek_fnc_dcamName,
    _lbl
];

_bot ctrlSetStructuredText parseText format [
    "<t size='0.65' color='#8fa389'>alt %1 m  -  x%2  -  %3</t>",
    round ((getPosATL _uav) select 2),
    (round (_mag * 10)) / 10,
    _src
];
