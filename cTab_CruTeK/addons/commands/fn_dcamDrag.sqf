/*
    crutek_fnc_dcamDrag
    Brandeggio della torretta trascinando col tasto destro sul video.

    Funziona solo sui droni SENZA operatore collegato: se qualcuno prende la
    torretta il comando gli verrebbe strappato di mano, quindi si molla.

    La posizione del cursore si legge con getMousePosition invece di appoggiarsi
    all'evento MouseMoving: gli eventi del mouse sui controlli statici non sono
    affidabili, mentre il polling per frame lo e sempre.

    0: STRING - "START", "STOP" oppure "UPDATE" (default)
    Ritorna: BOOL - solo per "START", se il brandeggio e partito
*/

params [["_mode", "UPDATE"]];

// ------------------------------------------------------------------
if (_mode isEqualTo "STOP") exitWith {
    crutek_dcam_dragging = false;
    true
};

// ------------------------------------------------------------------
if (_mode isEqualTo "START") exitWith {
    if (!crutek_dcam_active) exitWith { false };
    // il brandeggio si puo disattivare per missione: e l'unica cosa che fa
    // agire invece che guardare
    if (!crutek_dcam_allowDrag) exitWith { false };
    if !(crutek_dcam_kind isEqualTo "DRONE") exitWith { false };
    if (crutek_dcam_hidden || {crutek_dcam_hasOp}) exitWith { false };

    private _uav = crutek_dcam_uav;
    if (isNull _uav) exitWith { false };

    // si parte dalla direzione in cui la torretta sta gia guardando
    // stessa doppia sorgente del puntamento in dcamFrame
    private _wd = if (crutek_dcam_aim in ["PILOTCAM", "NOSE", "TURRET"]) then {
        switch (crutek_dcam_aim) do {
            case "NOSE":   { vectorDir _uav };
            case "TURRET": { _uav weaponDirection ((weapons _uav) param [0, ""]) };
            default        { getPilotCameraDirection _uav };
        }
    } else {
        _uav vectorModelToWorld ((_uav selectionPosition crutek_dcam_posMem) vectorFromTo (_uav selectionPosition crutek_dcam_dirMem))
    };
    _wd params ["_vx", "_vy", "_vz"];
    private _h = sqrt ((_vx * _vx) + (_vy * _vy));

    crutek_dcam_aimAz    = _vx atan2 _vy;
    crutek_dcam_aimEl    = atan (_vz / (_h max 1e-6));
    crutek_dcam_dragLast = getMousePosition;
    crutek_dcam_dragTick = 0;
    crutek_dcam_dragging = true;

    true
};

// ------------------------------------------------------------------ UPDATE
if (!crutek_dcam_active || {!crutek_dcam_dragging}) exitWith {};

private _uav = crutek_dcam_uav;
if (isNull _uav) exitWith { crutek_dcam_dragging = false };

if (crutek_dcam_hasOp) exitWith {
    crutek_dcam_dragging = false;
    ["DroneCam", "Torretta presa da un operatore"] call crutek_fnc_dcamNotify;
};

private _m = getMousePosition;
_m params [["_mx", 0], ["_my", 0]];
crutek_dcam_dragLast params [["_lx", 0], ["_ly", 0]];
crutek_dcam_dragLast = _m;

private _dx = _mx - _lx;
private _dy = _my - _ly;
if (_dx isEqualTo 0 && {_dy isEqualTo 0}) exitWith {};

crutek_dcam_picRect params ["", "", ["_pw", 1], ["_ph", 1]];
if (_pw <= 0 || {_ph <= 0}) exitWith {};

/*
    Sensibilita legata all'inquadratura: trascinando per tutta la larghezza
    del video ci si sposta di un campo visivo, quindi il gesto resta uguale
    a ogni ingrandimento invece di diventare ingestibile a zoom alto.
*/
private _fovDeg = 2 * (atan crutek_dcam_fovApplied);
private _ratio  = (crutek_dcam_fovAuto * ((getResolution select 0) / ((getResolution select 1) max 1))) max 0.01;

crutek_dcam_aimAz = crutek_dcam_aimAz + (((_dx / _pw) * _fovDeg) * crutek_dcam_dragSens);
crutek_dcam_aimEl = crutek_dcam_aimEl - (((_dy / _ph) * (_fovDeg / _ratio)) * crutek_dcam_dragSens);
crutek_dcam_aimEl = (crutek_dcam_aimEl max -89) min 30;

// non si inonda la rete: si comanda al massimo dieci volte al secondo
if (diag_tickTime < crutek_dcam_dragTick) exitWith {};
crutek_dcam_dragTick = diag_tickTime + 0.1;

private _ch  = cos crutek_dcam_aimEl;
private _dir = [(sin crutek_dcam_aimAz) * _ch, (cos crutek_dcam_aimAz) * _ch, sin crutek_dcam_aimEl];

/*
    Il punto a cui si blocca la torretta e quello dove la mira TOCCA TERRA,
    non un punto a distanza fissa lungo la direzione.

    lockCameraTo inchioda la camera a una posizione del mondo. Con un punto
    scelto a quattromila metri lungo la linea di mira, quel punto resta
    sospeso in aria oltre il terreno: la torretta ci resta puntata, ma mentre
    il drone vola il suolo sotto scorre via per parallasse. E' quello che si
    vedeva passando dal terminale al telefono dopo un Ctrl+T.

    Cercando invece l'intersezione con la superficie si blocca esattamente
    quel pezzo di terreno, o quel tetto, e l'inquadratura resta ferma sul
    posto mentre il drone gira intorno: lo stesso comportamento del blocco
    del terminale.

    Se la linea non incontra niente - mira all'orizzonte o verso il cielo -
    si torna al punto lontano, che li e l'unica cosa sensata.
*/
private _da  = getPosASL _uav;
private _fin = _da vectorAdd (_dir vectorMultiply 8000);
private _hit = lineIntersectsSurfaces [_da, _fin, _uav, objNull, true, 1, "GEOM", "NONE"];
private _pos = if (_hit isEqualTo []) then { _fin } else { (_hit select 0) select 0 };

// eseguito dove il drone e locale, altrimenti la torretta non si muove davvero
[_uav, [_pos, [0]]] remoteExec ["lockCameraTo", _uav];
crutek_dcam_locked = true;
