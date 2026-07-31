/*
    crutek_fnc_dcamHud
    Riempie le due bande sopra il feed.

    Schema uguale su tutte le sorgenti:

        alto    LA TUA quota  |  LA TUA prua  |  LE TUE coordinate
        basso   filtro e ingrandimento  |     |  nome della sorgente

    La riga alta parla di TE, non di quello che stai guardando: e la tua
    telemetria, come nella barra di stato di cTab. Quello che riguarda il
    feed - filtro, ingrandimento, nome della sorgente - sta tutto in basso.
    Cosi non c'e ambiguita su quale delle due posizioni stai leggendo.

    Il nome sta in basso a destra per un motivo pratico oltre che estetico:
    tenendolo fuori dalla riga alta, quella riga resta corta e la prua al
    centro non viene mai spinta di lato da un nome lungo.

    Le scritte sono bianche col contorno nero, e passano al verde solo in
    notturno. Il contorno e cio che le rende leggibili sul cielo chiaro senza
    dover scurire la banda, che altrimenti mangerebbe immagine.
*/

disableSerialization;
if (crutek_dcam_overlayOn isEqualTo "") exitWith {};

private _d = uiNamespace getVariable [crutek_dcam_overlayOn, displayNull];
if (isNull _d) exitWith {};

private _uav = crutek_dcam_uav;
if (isNull _uav) exitWith {};

private _hcam = crutek_dcam_kind isEqualTo "HCAM";

// ---- modo in uso, in forma breve --------------------------------
private _fnc_short = {
    switch (_this) do {
        case "NVG":    { "NV" };
        case "THERM1": { "TH1" };
        case "THERM2": { "TH2" };
        default        { "D-TV" };
    };
};

private _eff = if (_hcam) then {
    private _last = (count crutek_dcam_modesHcam) - 1;
    crutek_dcam_modesHcam select ((crutek_dcam_mode max 0) min _last)
} else {
    crutek_dcam_effective
};

private _sel = if (_hcam) then {
    if ((crutek_dcam_mode max 0) isEqualTo 0) then { "AUTO" } else { _eff }
} else {
    crutek_dcam_modes select crutek_dcam_mode
};

private _filtro = if (_sel isEqualTo "AUTO") then {
    format ["AUTO - %1", _eff call _fnc_short]
} else {
    _sel call _fnc_short
};

// verde solo col notturno, bianco in tutto il resto
private _col = if (_eff isEqualTo "NVG") then { crutek_dcam_hudColorNV } else { crutek_dcam_hudColor };

// ---- prua: la TUA, lettera cardinale piu gradi su tre cifre -------
private _dir = getDir player;
_dir = (_dir % 360 + 360) % 360;

private _lettera = crutek_dcam_compass select (floor (((_dir + 22.5) % 360) / 45));

private _gradi = str (round _dir);
if ((round _dir) >= 360) then { _gradi = "0" };
while {(count _gradi) < 3} do { _gradi = "0" + _gradi };

// ---- la TUA quota -------------------------------------------------
private _quota = format ["alt %1 m", round ((getPosATL player) select 2)];

/*
    L'ingrandimento riguarda il feed, non te: sta in basso accanto al filtro.

    E riferito all'ottica piu larga del mezzo, letta dalla sua config: e lo
    stesso riferimento del CAM MAG in torretta, quindi i due numeri
    coincidono. La correzione di forma non e zoom e si toglie dal conto.
    Sulle helmet cam non si mostra, che hanno campo fisso.
*/
if (!_hcam) then {
    private _wide = if (crutek_dcam_ladder isEqualTo []) then { 0.37 } else { crutek_dcam_ladder select 0 };
    private _fov  = crutek_dcam_fovApplied / (crutek_dcam_fovAuto max 0.001);
    private _mag  = (_wide / (_fov max 0.001)) * crutek_dcam_cropZoom;
    _filtro = format ["%1  -  x%2", _filtro, (round (_mag * 10)) / 10];
};

// ---- nome ---------------------------------------------------------
private _nome = [_uav] call crutek_fnc_dcamName;
if (_hcam) then { _nome = format ["OpCam: %1", _nome] };

// ---- scrittura ----------------------------------------------------
private _fnc_scrivi = {
    params ["_idc", "_testo", ["_size", "0.7"], ["_align", "left"]];
    private _c = _d displayCtrl _idc;
    if (isNull _c) exitWith {};
    _c ctrlSetStructuredText parseText format [
        "<t align='%4' size='%3' color='%2' shadow='2' shadowColor='#000000'>%1</t>",
        _testo, _col, _size, _align
    ];
};

[crutek_dcam_idcTopL, _quota] call _fnc_scrivi;
[crutek_dcam_idcTopC, format ["%1 %2", _lettera, _gradi], "0.7", "center"] call _fnc_scrivi;
[crutek_dcam_idcTopR, mapGridPosition player, "0.7", "right"] call _fnc_scrivi;

[crutek_dcam_idcBotL, _filtro, "0.65"] call _fnc_scrivi;
[crutek_dcam_idcBotC, ""] call _fnc_scrivi;
[crutek_dcam_idcBotR, _nome, "0.65", "right"] call _fnc_scrivi;
